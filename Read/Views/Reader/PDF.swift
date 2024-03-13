//
//  Reader.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import PDFKit
import RealmSwift
import SwiftUI

public extension PDFAnnotationKey {
    static let highlightId: PDFAnnotationKey = .init(rawValue: "/HID")
}

struct PDF: View {
    var realm = try! Realm()
    let url: URL
    let book: Book

    @StateObject var pdfViewModel: PDFViewModel

    @State var showSettingsSheet = false
    @State var showContentSheet = false
    @State var showOverlay = false
    @State var showContextMenu: Bool = false
    @State var contextMenuPosition: CGPoint = .zero
    @State var editMode = false

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
            }, currentTocItemId: pdfViewModel.currentTocItem?.id)
        })
        .sheet(isPresented: $showSettingsSheet, content: {
            ReaderSettings(theme: $pdfViewModel.theme, isPDF: true, updateTheme: {
                pdfViewModel.setTheme()
            })

        })
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
            pdfViewModel.copySelection()
        case .delete:

            if let tappedHighlight = pdfViewModel.tappedHighlight, let thawedBook = book.thaw(), let realm = thawedBook.realm {
                if let highlightIndex = book.highlights.firstIndex(where: { $0.highlightId == tappedHighlight.uuidString }) {
                    try! realm.write {
                        thawedBook.highlights.remove(at: highlightIndex)
                    }
                    if let deleteHighlight = book.highlights[highlightIndex].toPDFHighlight() {
                        pdfViewModel.removeHighlight(highlight: deleteHighlight)
                    }
                }
            }
        }

        showContextMenu = false
        editMode = false
        pdfViewModel.tappedHighlight = nil
    }

    func handleHighlight(_ newHighlight: PDFHighlight) {
        guard let thawedBook = book.thaw() else {
            return
        }

        try! realm.write {
            let newHighlight = BookHighlight(pdfHighlight: newHighlight)
            newHighlight?.chapterTitle = pdfViewModel.currentLabel // add info to PDFHighlight struct

            if let newHighlight {
                thawedBook.highlights.append(newHighlight)
            }
        }
    }

    func relocated(_ currentPage: PDFPage) {
        showContextMenu = false
        editMode = false
        pdfViewModel.pdfView.clearSelection()

        let pdfDocument = pdfViewModel.pdfDocument

        let totalPages = CGFloat(pdfDocument.pageCount)
        let currentPageIndex = CGFloat(pdfDocument.index(for: currentPage))
        let updatedAt: Date = .now

        let thawedBook = book.thaw()
        try! realm.write {
            if thawedBook?.readingPosition == nil {
                thawedBook?.readingPosition = ReadingPosition()
                thawedBook?.readingPosition?.progress = currentPageIndex / totalPages
                thawedBook?.readingPosition?.updatedAt = updatedAt
                thawedBook?.readingPosition?.chapter = Int(currentPageIndex)

            } else {
                thawedBook?.readingPosition?.progress = currentPageIndex / totalPages
                thawedBook?.readingPosition?.updatedAt = updatedAt
                thawedBook?.readingPosition?.chapter = Int(currentPageIndex)
            }
        }
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
