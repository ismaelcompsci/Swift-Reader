//
//  EBookView.swift
//  Read
//
//  Created by Mirna Olvera on 3/6/24.
//

import SwiftReader
import SwiftUI

struct EBookView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var ebookViewModel: EBookReaderViewModel

    var book: SDBook
    var url: URL

    @State var contextMenuPosition: CGPoint = .zero
    @State var editMode = false
    @State var showContentSheet = false
    @State var showSettingsSheet = false
    @State var showContextMenu = false
    @State var showHighlightSheet = false
    @State var showOverlay = false
    @State var currentHighlight: TappedHighlight? = nil
    @State var showRefrenceLibrary = false
    @State var refrenceLibraryText = "" { didSet { showRefrenceLibrary = true }}

    init(url: URL, book: SDBook) {
        self.book = book
        self.url = url
        if let cfi = book.position?.epubCfi {
            self._ebookViewModel = StateObject(
                wrappedValue: EBookReaderViewModel(
                    file: url,
                    delay: .milliseconds(500),
                    startCfi: cfi
                )
            )

        } else {
            self._ebookViewModel = StateObject(
                wrappedValue: EBookReaderViewModel(
                    file: url,
                    delay: .milliseconds(500)
                )
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                let section = ebookViewModel.currentLocation?.section

                if let section = section, showOverlay == true {
                    Text(verbatim: "\(section.total - section.current) pages left in chapter")

                } else {
                    Text("\(book.title)")
                        .transition(
                            .move(edge: .leading).combined(with: .opacity).animation(
                                .snappy
                            )
                        )
                }
            }
            .foregroundStyle(Color(hex: ebookViewModel.theme.fg.rawValue).opacity(0.5))
            .font(.footnote.bold())
            .transition(.blurReplace.combined(with: .opacity))
            .frame(minHeight: 30)
            .padding(.horizontal, 16)

            EBookReader(viewModel: ebookViewModel)
                .onTapGesture {
                    Task {
                        let hasSelection = try await ebookViewModel.hasSelection()

                        if hasSelection {
                            showContextMenu = false
                        }
                    }
                }

            HStack {
                let current = ebookViewModel.currentLocation?.location?.current
                let total = ebookViewModel.currentLocation?.location?.total

                Group {
                    if let current = current, showOverlay == false {
                        Text(verbatim: "\(current)")
                    } else if let current = current, let total = total, showOverlay == true {
                        Text(verbatim: "\(current) of \(total)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(minHeight: 30)
            .font(.footnote.bold())
            .foregroundStyle(Color(hex: ebookViewModel.theme.fg.rawValue).opacity(0.5))
            .transition(.blurReplace.combined(with: .opacity))
            .padding(.horizontal, 16)
        }
        .overlay {
            if showContextMenu && contextMenuPosition != .zero {
                ReaderContextMenu(
                    showContextMenu: $showContextMenu,
                    editMode: $editMode,
                    position: contextMenuPosition,
                    onEvent: handleContentMenuEvent
                )
            }
        }
        .overlay {
            VStack {
                HStack {
                    Spacer()
                    if showOverlay == true {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 30, height: 30)
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(.circle)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                ReaderSettingsButton(
                    show: $showOverlay,
                    progress: ebookViewModel.currentLocation?.fraction ?? .zero
                ) { event in
                    switch event {
                    case .settings:
                        showSettingsSheet = true

                    case .bookmarks:
                        showHighlightSheet = true

                    case .content:
                        showContentSheet = true
                    }
                }
            }
        }
        .background(Color(hex: ebookViewModel.theme.bg.rawValue))
        .overlay {
            switch ebookViewModel.state {
            case .loading:
                ZStack {
                    Color(hex: ebookViewModel.theme.bg.rawValue)
                        .ignoresSafeArea()

                    ProgressView()
                }
            case .done:
                EmptyView()
            case .failure:
                ZStack {
                    Color(hex: ebookViewModel.theme.bg.rawValue)
                        .ignoresSafeArea()

                    VStack {
                        Text("Something went wrong")

                        Button("Return") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showContentSheet, content: {
            ReaderContent(toc: ebookViewModel.toc ?? [], isSelected: { item in ebookViewModel.isBookTocItemSelected(item: item) }, tocItemPressed: { item in
                ebookViewModel.goTo(cfi: item.href)
                showContentSheet = false
            }, currentTocItemId: ebookViewModel.currentTocItem?.id)
        })
        .sheet(isPresented: $showSettingsSheet, content: {
            ReaderSettings(bookTheme: $ebookViewModel.theme, isPDF: false) {
                ebookViewModel.setBookTheme()
            }

        })
        .sheet(isPresented: $showHighlightSheet, content: {
            Text("Not implemented.")
        })
        .refrenceLibrary(isPresented: $showRefrenceLibrary, term: refrenceLibraryText)
        .onReceive(ebookViewModel.onTapped, perform: handleTap)
        .onReceive(ebookViewModel.onRelocated, perform: relocated)
        .onReceive(ebookViewModel.onSelectionChanged, perform: selectionChanged)
        .onReceive(ebookViewModel.onHighlighted, perform: newHighlight)
        .onReceive(ebookViewModel.onTappedHighlight, perform: handleTappedHighlight)
        .onChange(of: ebookViewModel.renderedBook) { oldValue, newValue in
            if oldValue == false, newValue == true {
                // inject highlights
                var annotations = [Annotation]()

                book.highlights.forEach { highlight in

                    guard let cfi = highlight.cfi, let index = highlight.chapter else {
                        return
                    }

                    let ann = Annotation(index: index, value: cfi, color: highlight.backgroundColor)
                    annotations.append(ann)
                }

                ebookViewModel.setBookAnnotations(annotations: annotations)
            }
        }
        .onChange(of: showContextMenu) { oldValue, newValue in
            if oldValue == true, newValue == false {
                editMode = false
            }
        }
    }

    private func handleContentMenuEvent(_ event: ContextMenuEvent) {
        switch event {
        case .highlight:
            ebookViewModel.highlightSelection()
        case .copy:
            if editMode == true, let currentHighlight {
                ebookViewModel.setPastboardText(with: currentHighlight.text)

            } else {
                ebookViewModel.copySelection()
            }
        case .delete:
            if let value = currentHighlight?.value {
                ebookViewModel.removeHighlight(value)
                book.removeHighlight(value: value)
            }
        case .lookup:
            if editMode == true {
                refrenceLibraryText = currentHighlight?.text ?? ""
            } else {
                ebookViewModel.getSelection { text in
                    if let text {
                        self.refrenceLibraryText = text
                    }
                }
            }
        }

        showContextMenu = false
        currentHighlight = nil
    }

    private func handleTappedHighlight(_ highlight: TappedHighlight) {
        showContextMenu = false

        let yPad = highlight.dir == "down" ? 70 : -35.0
        let annotationViewPosition = CGPoint(
            x: highlight.x,
            y: highlight.y + yPad
        )

        editMode = true
        currentHighlight = highlight
        contextMenuPosition = annotationViewPosition
        showContextMenu = true
    }

    private func newHighlight(highlight: (String, String?, Int?, String?)) {
        let (text, cfi, index, label) = highlight

        guard let cfi, let label, let index else {
            print("Missing selection data")
            return
        }

        book.addHighlight(
            text: text,
            cfi: cfi,
            index: index,
            label: label,
            addedAt: .now,
            updatedAt: .now
        )
    }

    private func selectionChanged(selectionSelected: Selection?) {
        showContextMenu = false
        editMode = false

        guard let selectedText = selectionSelected?.string, selectedText.count > 0 else {
            showContextMenu = false
            return
        }

        guard let bounds = selectionSelected?.bounds else {
            showContextMenu = false
            return
        }

        let yPadding = selectionSelected?.dir == "down" ? 70.0 : -35.0
        let annotationViewPosition = CGPoint(
            x: bounds.origin.x,
            y: bounds.origin.y + yPadding
        )

        contextMenuPosition = annotationViewPosition
        showContextMenu = true
    }

    private func relocated(relocate: Relocate) {
        book.updatePosition(with: relocate)
    }

    private func handleTap(point: CGPoint) {
        showContextMenu = false

        withAnimation {
            showOverlay.toggle()
        }
    }
}
