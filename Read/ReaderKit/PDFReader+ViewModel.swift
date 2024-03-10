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

class PDFViewModel: ObservableObject {
    var pdfFile: URL

    var pdfDocument: PDFDocument
    var pdfView: NoContextMenuPDFView
    var pdfInitialPageIndex: Int?

    @Published var theme = Theme()
    @Published var currentPage: PDFPage?
    @Published var currentTocItem: PDFTocItem?
    @Published var currentLabel: String = ""

    var toc: [PDFTocItem]? {
        getPdfToc()
    }

    var onRelocated = PassthroughSubject<PDFPage, Never>()
    // pdf selection event nothing is passed through
    // highlighting can be accessed by pdfview.currentSelection
    var onSelectionChanged = PassthroughSubject<Void, Never>()
    var onHighlighted = PassthroughSubject<(String, [PDFHighlight]), Never>()
    var onTapped = PassthroughSubject<CGPoint, Never>()

    init(pdfFile: URL, pdfInitialPageIndex: Int? = nil) {
        self.pdfFile = pdfFile
        self.pdfDocument = PDFDocument(url: pdfFile) ?? PDFDocument()
        self.pdfView = NoContextMenuPDFView()
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

        currentTocItem = getPDFCurrentTocItem(from: page)
        currentLabel = currentTocItem?.outline?.label ?? ""

        onRelocated.send(page)
    }

    func goTo(pageIndex: Int) {
        if let page = pdfDocument.page(at: pageIndex) {
            pdfView.go(to: page)
        }
    }

    private var currentTocItemHolder: PDFTocItem?
    private func getPDFCurrentTocItem(from: PDFPage) -> PDFTocItem? {
        guard let toc else {
            return nil
        }

        let first = toc.last { tocItem in
            tocItem.outline?.destination?.page?.pageRef?.pageNumber == from.pageRef?.pageNumber
        }

        if first == nil {
            return currentTocItemHolder
        }

        currentTocItemHolder = first

        return first
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
        // single highlight but possible to highlight between multiple pages
        var pdfHighlightPageLocations = [PDFHighlight]()

        guard let currentSelection = pdfView.currentSelection else {
            return
        }

        currentSelection.pages.forEach { selectionPage in
            guard let selectionPageNumber = selectionPage.pageRef?.pageNumber else { return }
            var pdfHighlightPage = PDFHighlight(page: selectionPageNumber, ranges: [])
            for i in 0 ..< currentSelection.numberOfTextRanges(on: selectionPage) {
                let selectionPageRange = currentSelection.range(at: i, on: selectionPage)

                pdfHighlightPage.ranges.append(selectionPageRange)
            }

            pdfHighlightPageLocations.append(pdfHighlightPage)
        }

        addHighlightToPages(highlight: pdfHighlightPageLocations)

        let selectedString = currentSelection.string ?? ""
        onHighlighted.send((selectedString, pdfHighlightPageLocations))
    }

    func addHighlightToPages(highlight: [PDFHighlight]) {
        highlight.forEach { highlightPageLocation in
            guard let highlightPage = self.pdfDocument.page(at: highlightPageLocation.page - 1) else { return }

            highlightPageLocation.ranges.forEach { highlightPageRange in
                guard let highlightSelection = self.pdfDocument.selection(from: highlightPage, atCharacterIndex: highlightPageRange.lowerBound, to: highlightPage, atCharacterIndex: highlightPageRange.upperBound)
                else { return }

                highlightSelection.selectionsByLine().forEach { hightlightSelectionByLine in
                    let annotation = PDFAnnotation(
                        bounds: hightlightSelectionByLine.bounds(for: highlightPage),
                        forType: .highlight,
                        withProperties: nil
                    )

                    annotation.endLineStyle = .square // custom
                    annotation.color = UIColor.yellow.withAlphaComponent(1) // custom
                    highlightPage.addAnnotation(annotation)

                    self.pdfView.clearSelection()
                }
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
}
