//
//  Reader.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import PDFKit
import RealmSwift
import SwiftUI

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
                ReaderContextMenu(showContextMenu: $showContextMenu, position: contextMenuPosition, highlightButtonPressed: pdfViewModel.highlightSelection, copyButtonPressed: pdfViewModel.copySelection)
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
        .onAppear {
            // convert stored highlights to pdfhighlihgs

            var highlights = [PDFHighlight]()

            Array(book.highlights).forEach { bH in
                bH.position.forEach { pdfHighlight in
                    let page = pdfHighlight.page
                    var ranges = [NSRange]()

                    pdfHighlight.ranges.forEach { hRange in
                        let range = NSRange(location: hRange.lowerBound, length: hRange.uppperBound - hRange.lowerBound)

                        ranges.append(range)
                    }

                    highlights.append(PDFHighlight(page: page, ranges: ranges))
                }
            }

            pdfViewModel.addHighlightToPages(highlight: highlights)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }

    func handleHighlight(_ highlight: (String, [PDFHighlight])) {
        let (text, newHighlight) = highlight

        guard let thawedBook = book.thaw() else {
            return
        }

        var pageNumber: Int?

        try! realm.write {
            let pHighlight = BookHighlight()

            newHighlight.forEach { hPage in
                let pdfHighlight = PersistedPDFHighlight()
                pdfHighlight.page = hPage.page

                if pageNumber != nil {
                    pageNumber = hPage.page
                }

                _ = hPage.ranges.map { range in
                    let highlightRange = HighlightRange()
                    highlightRange.lowerBound = range.lowerBound
                    highlightRange.uppperBound = range.upperBound

                    pdfHighlight.ranges.append(highlightRange)
                }

                pHighlight.position.append(pdfHighlight)
            }

            pHighlight.addedAt = .now
            pHighlight.updatedAt = .now
            pHighlight.chapter = pageNumber
            pHighlight.chapterTitle = pdfViewModel.currentLabel
            pHighlight.highlightText = text

            thawedBook.highlights.append(pHighlight)
        }
    }

    func relocated(_ currentPage: PDFPage) {
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

            return
        }

        withAnimation {
            showOverlay.toggle()
        }
    }
}

#Preview {
    PDF(url: URL(string: "")!, book: .example1)
}