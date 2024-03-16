//
//  Reader.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import PDFKit
import SwiftUI

public extension PDFAnnotationKey {
    static let highlightId: PDFAnnotationKey = .init(rawValue: "/HID")
}

struct PDF: View {
    let url: URL
    let book: Book

    @StateObject var pdfViewModel: PDFViewModel

    @State var showSettingsSheet = false
    @State var showContentSheet = false
    @State var showOverlay = false
    @State var showContextMenu: Bool = false
    @State var contextMenuPosition: CGPoint = .zero
    @State var editMode = false
    @State var showRefrenceLibrary = false
    @State var refrenceLibraryText = ""

    init(url: URL, book: Book) {
        self.book = book
        self.url = url
        self._pdfViewModel = StateObject(wrappedValue: PDFViewModel(pdfFile: url, pdfInitialPageIndex: book.readingPosition?.chapter))
    }

    var body: some View {
        ZStack {
            Color(hex: pdfViewModel.theme.bg.rawValue)
                .ignoresSafeArea()

            PDFReader(viewModel: pdfViewModel, url: url)

            ReaderOverlay(title: book.title, currentLabel: pdfViewModel.currentLabel, showOverlay: $showOverlay, settingsButtonPressed: {
                showSettingsSheet.toggle()
            }) {
                showContentSheet.toggle()
            }

            if showContextMenu && contextMenuPosition != .zero {
                ReaderContextMenu(showContextMenu: $showContextMenu, editMode: $editMode, position: contextMenuPosition, onEvent: handleContentMenuEvent)
            }
        }

        .sheet(isPresented: $showContentSheet, content: {
            ReaderContent(toc: pdfViewModel.toc ?? [], isSelected: { item in pdfViewModel.isBookTocItemSelected(item: item) }, tocItemPressed: { item in
                guard let page = item.outline?.destination?.page else {
                    return
                }
                pdfViewModel.pdfView.go(to: page)
                showContentSheet = false
            }, currentTocItemId: pdfViewModel.currentTocItem?.id)
        })
        .sheet(isPresented: $showSettingsSheet, content: {
            ReaderSettings(theme: $pdfViewModel.theme, isPDF: true, updateTheme: {
                pdfViewModel.setTheme()
            })

        })
        .refrenceLibrary(isPresented: $showRefrenceLibrary, term: refrenceLibraryText)
        .onReceive(pdfViewModel.onSelectionChanged, perform: selectionChanged)
        .onReceive(pdfViewModel.onRelocated, perform: relocated)
        .onReceive(pdfViewModel.onTapped, perform: handleTap)
        .onReceive(pdfViewModel.onHighlighted, perform: handleHighlight)
        .onReceive(pdfViewModel.onTappedHighlight, perform: handleTappedHighlight)
        .onAppear {
            // convert stored highlights to pdfhighlihgs
            book.highlights.compactMap { $0.toPDFHighlight() }.forEach { pdfHighlight in
                pdfViewModel.addHighlightToPages(highlight: pdfHighlight)
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }

    private func handleTappedHighlight(_ highlight: TappedPDFHighlight) {
        showContextMenu = false
        let topPadding = 36.0

        let annotationViewPosition = CGPoint(
            x: highlight.bounds.midX,
            y: highlight.bounds.maxY - topPadding
        )

        editMode = true
        contextMenuPosition = annotationViewPosition
        showContextMenu = true
    }

    private func handleContentMenuEvent(_ event: ContextMenuEvent) {
        switch event {
        case .highlight:
            pdfViewModel.highlightSelection()
        case .copy:
            if editMode == true,
               let tappedHighlight = pdfViewModel.tappedHighlight,
               let high = pdfViewModel.getHighlight(with: tappedHighlight),
               let text = high.selection.string
            {
                pdfViewModel.setPastboardText(with: text)

            } else {
                pdfViewModel.copySelection()
            }
        case .delete:

            if let tappedHighlight = pdfViewModel.tappedHighlight {
                book.removeHighlight(withId: tappedHighlight.uuidString)
                pdfViewModel.removeHighlight(withUUIDString: tappedHighlight.uuidString)
            }

        case .lookup:
            if editMode == true,
               let tappedHighlight = pdfViewModel.tappedHighlight,
               let high = pdfViewModel.getHighlight(with: tappedHighlight),
               let text = high.selection.string
            {
                refrenceLibraryText = text
                showRefrenceLibrary = true
            } else {
                if let text = pdfViewModel.getSelection() {
                    refrenceLibraryText = text
                    showRefrenceLibrary = true
                }
            }
        }

        showContextMenu = false
        editMode = false
        pdfViewModel.tappedHighlight = nil
    }

    func handleHighlight(_ newHighlight: PDFHighlight) {
        book.addHighlight(pdfHighlight: newHighlight)
    }

    func relocated(_ currentPage: PDFPage) {
        showContextMenu = false
        editMode = false
        pdfViewModel.pdfView.clearSelection()

        book.updateReadingPosition(page: currentPage, document: pdfViewModel.pdfDocument)
    }

    func selectionChanged(_ _: Any?) {
        showContextMenu = false
        editMode = false

        guard let selection = pdfViewModel.pdfView.currentSelection,
              let selectionString = selection.string,
              selectionString.count > 0
        else {
            showContextMenu = false
            return
        }

        guard let selectionLastLine = selection.selectionsByLine().last,
              let selectionLastLinePage = selectionLastLine.pages.last
        else {
            showContextMenu = false
            return
        }

        let selectionBound = selectionLastLine.bounds(for: selectionLastLinePage)
        let selectionInView = pdfViewModel.pdfView.convert(selectionBound, from: selectionLastLinePage)

        let annotationViewPosition = CGPoint(
            x: selectionInView.minX + selectionInView.width / 2.0,
            y: selectionInView.minY + 52
        )

        contextMenuPosition = annotationViewPosition
        showContextMenu = true
    }

    private func handleTap(point: CGPoint) {
        guard let currentPage = pdfViewModel.currentPage else {
            return
        }

        if pdfViewModel.pdfView.currentSelection != nil {
            let bounds = pdfViewModel.pdfView.currentSelection?.bounds(for: currentPage)

            if let bounds {
                if bounds.contains(point) {
                    return
                }
            }

            pdfViewModel.pdfView.clearSelection()
            showContextMenu = false

            return
        }

        withAnimation {
            if showContextMenu == false {
                showOverlay.toggle()
            }
        }
        showContextMenu = false
    }
}

#Preview {
    PDF(url: URL(string: "")!, book: .example1)
}
