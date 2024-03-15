//
//  PDFReader+ViewModel.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import Combine
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct TappedPDFHighlight {
    var bounds: CGRect
    var UUID: UUID
}

class PDFViewModel: ObservableObject {
    var pdfFile: URL

    var pdfDocument: PDFDocument
    var pdfView: NoContextMenuPDFView
    var pdfInitialPageIndex: Int?

    @Published var theme = Theme()
    @Published var currentPage: PDFPage?
    @Published var currentTocItem: PDFTocItem?
    @Published var currentLabel: String = ""

    var highlights = [UUID: [HighlightValue]]()
    var tappedHighlight: UUID?

    var toc: [PDFTocItem]? {
        getPdfToc()
    }

    var onRelocated = PassthroughSubject<PDFPage, Never>()
    // pdf selection event nothing is passed through
    // highlighting can be accessed by pdfview.currentSelection
    var onSelectionChanged = PassthroughSubject<Void, Never>()
    var onHighlighted = PassthroughSubject<PDFHighlight, Never>()
    var onTappedHighlight = PassthroughSubject<TappedPDFHighlight, Never>()
    var onTapped = PassthroughSubject<CGPoint, Never>()

    init(pdfFile: URL, pdfInitialPageIndex: Int? = nil) {
        self.pdfFile = pdfFile
        self.pdfDocument = PDFDocument(url: pdfFile) ?? PDFDocument()
        self.pdfView = NoContextMenuPDFView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.pdfInitialPageIndex = pdfInitialPageIndex

        setTheme()
    }

    func setTheme() {
        let rgba = getRGBFromHex(hex: theme.bg.rawValue)

        pdfView.backgroundColor = UIColor(red: rgba["red"] ?? 0, green: rgba["green"] ?? 0, blue: rgba["blue"] ?? 0, alpha: 1)
        PDFPageCustomBackground.bg = CGColor(red: rgba["red"] ?? 0, green: rgba["green"] ?? 0, blue: rgba["blue"] ?? 0, alpha: 1)

        pdfView.goToNextPage(nil)
        pdfView.goToPreviousPage(nil)

        theme.save()
    }

    func pdfPageChanged() {
        currentPage = pdfView.currentPage
        // Disable popup menu
        pdfView.disableMenuInteractions()

        guard let page = pdfView.currentPage else {
            print(" pdfPageChanged: No page")
            return
        }

        if let pageNumber = page.pageRef?.pageNumber,
           let tocItem = getTocItem(for: pageNumber)
        {
            currentTocItem = tocItem
            currentLabel = tocItem.label
        }

        onRelocated.send(page)
    }

    func goTo(pageIndex: Int) {
        if let page = pdfDocument.page(at: pageIndex) {
            pdfView.go(to: page)
        }
    }

    func getTocItem(for pageIndex: Int) -> PDFTocItem? {
        if let toc {
            for i in 0 ..< toc.count - 1 {
                let nextIndex = i + 1
                let nextTocItem = toc[nextIndex]

                let currentTocItem = toc[i]

                let currentTocPageNumber = currentTocItem.pageNumber
                let nextTocPageNumber = nextTocItem.pageNumber

                if let currentTocPageNumber, let nextTocPageNumber {
                    if currentTocPageNumber == pageIndex {
                        return currentTocItem
                    }

                    if currentTocPageNumber < pageIndex && pageIndex < nextTocPageNumber {
                        return currentTocItem
                    }

                    if nextTocPageNumber == pageIndex {
                        return nextTocItem
                    }
                }
            }
        }

        return nil
    }

    func isBookTocItemSelected(item: PDFTocItem) -> Bool {
        let pdfSelected = item.outline?.hashValue == currentTocItem?.outline?.hashValue

        return pdfSelected
    }

    private func getPdfToc() -> [PDFTocItem]? {
        var toc = [PDFTocItem]()
        if let root = pdfDocument.outlineRoot {
            var stack: [(outline: PDFOutline, depth: Int)] = [(root, -1)]
            while !stack.isEmpty {
                let (current, depth) = stack.removeLast()
                if let label = current.label, !label.isEmpty {
                    toc.append(PDFTocItem(outline: current, depth: depth))
                }
                for i in (0 ..< current.numberOfChildren).reversed() {
                    if let child = current.child(at: i) {
                        stack.append((child, depth + 1))
                    }
                }
            }
        }

        return toc
    }

    func highlightSelection() {
        var pdfHighlightPageLocations = [PDFHighlight.PageLocation]()

        guard let currentSelection = pdfView.currentSelection else {
            return
        }

        currentSelection.pages.forEach { selectionPage in
            guard let selectionPageNumber = selectionPage.pageRef?.pageNumber else { return }
            var pdfHighlightPage = PDFHighlight.PageLocation(page: selectionPageNumber, ranges: [])
            for i in 0 ..< currentSelection.numberOfTextRanges(on: selectionPage) {
                let selectionPageRange = currentSelection.range(at: i, on: selectionPage)

                pdfHighlightPage.ranges.append(selectionPageRange)
            }

            pdfHighlightPageLocations.append(pdfHighlightPage)
        }

        let selectedString = currentSelection.string ?? "..."
        let highlight = PDFHighlight(uuid: .init(), pos: pdfHighlightPageLocations, content: selectedString)

        addHighlightToPages(highlight: highlight)
        onHighlighted.send(highlight)
    }

    func addHighlightToPages(highlight: PDFHighlight) {
        highlight.pos.forEach { highlightPageLocation in
            guard let highlightPage = self.pdfDocument.page(at: highlightPageLocation.page - 1) else { return }

            if highlights[highlight.uuid] == nil {
                highlights[highlight.uuid] = []
            }

            highlightPageLocation.ranges.forEach { highlightPageRange in
                guard let highlightSelection = self.pdfDocument.selection(from: highlightPage, atCharacterIndex: highlightPageRange.lowerBound, to: highlightPage, atCharacterIndex: highlightPageRange.upperBound)
                else { return }

                var highlightValue = HighlightValue(selection: highlightSelection)

                highlightSelection.selectionsByLine().forEach { hightlightSelectionByLine in
                    let annotation = PDFAnnotation(
                        bounds: hightlightSelectionByLine.bounds(for: highlightPage),
                        forType: .highlight,
                        withProperties: [PDFAnnotationKey.highlightId: highlight.uuid.uuidString]
                    )

                    annotation.endLineStyle = .square // custom
                    annotation.color = UIColor.yellow.withAlphaComponent(1) // custom

                    highlightPage.addAnnotation(annotation)
                    highlightValue.annotations.append(annotation)

                    self.pdfView.clearSelection()
                }

                highlights[highlight.uuid]?.append(highlightValue)
            }
        }
    }

    func copySelection() {
        let selections = pdfView.currentSelection?.string
        guard let text = selections else {
            return
        }
        UIPasteboard.general.setValue(text, forPasteboardType: UTType.plainText.identifier)
        pdfView.clearSelection()
    }

    func removeHighlight(highlight: PDFHighlight) {
        guard let highlightValue = highlights.removeValue(forKey: highlight.uuid) else { return }

        highlightValue.flatMap { $0.annotations }.forEach { annotation in
            annotation.page?.removeAnnotation(annotation)
        }
    }

    func removeHighlight(withUUIDString uuid: String) {
        guard let uuid = UUID(uuidString: uuid), let highlightValue = highlights.removeValue(forKey: uuid) else {
            return
        }

        highlightValue.flatMap { $0.annotations }.forEach { annotation in
            annotation.page?.removeAnnotation(annotation)
        }
    }
}

struct HighlightValue {
    let selection: PDFSelection
    var annotations: [PDFAnnotation] = []
}
