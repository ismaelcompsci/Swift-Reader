//
//  EBookView.swift
//  Read
//
//  Created by Mirna Olvera on 3/6/24.
//

import RealmSwift
import SwiftUI

struct EBookView: View {
    @StateObject var ebookViewModel: EBookReaderViewModel

    var realm = try! Realm()

    var book: Book
    var url: URL

    @State var contextMenuPosition: CGPoint = .zero
    @State var showContentSheet = false
    @State var showSettingsSheet = false
    @State var showContextMenu = false
    @State var showOverlay = false

    init(url: URL, book: Book) {
        self.book = book
        self.url = url
        if let cfi = book.readingPosition?.epubCfi {
            self._ebookViewModel = StateObject(wrappedValue: EBookReaderViewModel(file: url, delay: .milliseconds(500), startCfi: cfi))

        } else {
            self._ebookViewModel = StateObject(wrappedValue: EBookReaderViewModel(file: url, delay: .milliseconds(500)))
        }
    }

    var body: some View {
        ZStack {
            Color(hex: ebookViewModel.theme.bg.rawValue)
                .ignoresSafeArea()

            EBookReader(viewModel: ebookViewModel, url: url)
                .onTapGesture {
                    Task {
                        let hasSelection = try await ebookViewModel.hasSelection()

                        if hasSelection {
                            showContextMenu = false
                        }
                    }
                }

            ReaderOverlay(title: book.title, currentLabel: ebookViewModel.currentLabel, showOverlay: $showOverlay, settingsButtonPressed: {
                showSettingsSheet.toggle()
            }) {
                showContentSheet.toggle()
            }

            if showContextMenu && contextMenuPosition != .zero {
                ReaderContextMenu(showContextMenu: $showContextMenu, position: contextMenuPosition, highlightButtonPressed: ebookViewModel.highlightSelection, copyButtonPressed: ebookViewModel.copySelection)
            }
        }
        .overlay {
            if ebookViewModel.allDone == false {
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    ProgressView()
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showContentSheet, content: {
            ReaderContent(toc: ebookViewModel.toc ?? [], isSelected: { item in ebookViewModel.isBookTocItemSelected(item: item) }, tocItemPressed: { item in
                ebookViewModel.goTo(cfi: item.href)
                showContentSheet = false
            }, currentTocItemId: ebookViewModel.currentTocItem?.id)
        })
        .sheet(isPresented: $showSettingsSheet, content: {
            ReaderSettings(theme: $ebookViewModel.theme, isPDF: false) {
                ebookViewModel.setBookTheme()
            }

        })
        .onReceive(ebookViewModel.tapped, perform: handleTap)
        .onReceive(ebookViewModel.bookRelocated, perform: relocated)
        .onReceive(ebookViewModel.selectionChanged, perform: selectionChanged)
        .onReceive(ebookViewModel.highlighted, perform: newHighlight)
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
    }

    private func newHighlight(highlight: (String, String?, Int?, String?)) {
        let (text, cfi, index, label) = highlight

        guard let cfi, let label, let index else {
            print("Missing selection data")
            return
        }

        guard let thawedBook = book.thaw() else {
            print("Unable to thaw book")
            return
        }

        if let bookRealm = book.realm?.thaw() {
            try! bookRealm.write {
                let pHighlight = BookHighlight()
                pHighlight.highlightText = text
                pHighlight.cfi = cfi
                pHighlight.chapter = index
                pHighlight.chapterTitle = label
                pHighlight.addedAt = .now
                pHighlight.updatedAt = .now

                thawedBook.highlights.append(pHighlight)
            }
        }
    }

    private func selectionChanged(selectionSelected: Selection?) {
        showContextMenu = false

        guard let selectedText = selectionSelected?.string, selectedText.count > 0 else {
            showContextMenu = false
            return
        }

        guard let bounds = selectionSelected?.bounds else {
            showContextMenu = false
            return
        }

        let annotationViewPosition = CGPoint(
            x: bounds.origin.x,
            y: bounds.origin.y
        )

        contextMenuPosition = annotationViewPosition
        showContextMenu = true
    }

    private func relocated(relocate: Relocate) {
        let thawedBook = book.thaw()
        try! realm.write {
            if thawedBook?.readingPosition == nil {
                thawedBook?.readingPosition = ReadingPosition()
                thawedBook?.readingPosition?.progress = relocate.fraction
                thawedBook?.readingPosition?.updatedAt = relocate.updatedAt ?? .now
                thawedBook?.readingPosition?.epubCfi = relocate.cfi
            } else {
                thawedBook?.readingPosition?.progress = relocate.fraction
                thawedBook?.readingPosition?.updatedAt = relocate.updatedAt ?? .now
                thawedBook?.readingPosition?.epubCfi = relocate.cfi
            }
        }
    }

    private func handleTap(point: CGPoint) {
        showContextMenu = false

        withAnimation {
            showOverlay.toggle()
        }
    }
}

#Preview {
    EBookView(url: URL(string: "L")!, book: .example1)
}
