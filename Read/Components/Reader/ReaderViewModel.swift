//
//  ReaderViewModel.swift
//  Read
//
//  Created by Mirna Olvera on 2/15/24.
//

import Combine
import Foundation
import PDFKit
import UniformTypeIdentifiers
import WebKit

struct Annotation: Codable {
    var index: Int
    var value: String
    var color: String
}

struct HighlightPage {
    var page: Int
    var ranges: [NSRange]
}

struct Selection {
    var bounds: CGRect
    var string: String?
}

struct PDFTocItem {
    var outline: PDFOutline
    var depth: Int
}

struct BookTocItem: Identifiable {
    var depth: Int

    var outline: PDFOutline?

    var label: String?
    var href: String?
    var chapterId: Int?

    var id: Int {
        if let outline {
            return outline.hashValue
        } else {
            return chapterId ?? UUID().hashValue
        }
    }
}

/**
    Book files must be written to documents directory
 */
class ReaderViewModel: ObservableObject {
    let url: URL
    let isPDF: Bool

    var webView: CustomWebView?
    var pdfDocument: PDFDocument?
    var pdfView: NoContextMenuPDFView?

    let initialEBookPosition: String?
    let initialPDFPosition: Int?

    @Published var showSettingsSheet = false
    @Published var showContentSheet = false

    @Published var theme = Theme()
    @Published var currentPage: PDFPage?
    @Published var isLoading = true {
        didSet {
            if isLoading == false && !hasRenderedBook && !isPDF {
                loadBook(bookPath: url.absoluteString, bookPosition: initialEBookPosition)
            }
        }
    }

    @Published var hasRenderedBook = false { didSet {
        setEbookToc()
    }}

    // MARK: Events

    var bookRelocated = PassthroughSubject<Relocate, Never>()
    var pdfRelocated = PassthroughSubject<PDFPage, Never>()
    var tapped = PassthroughSubject<CGPoint, Never>()
    var selectionChanged = PassthroughSubject<Selection?, Never>()
    /// 0 text, 1 pdfHighlight, 2 cfi,  3 index, 4 label
    var highlighted = PassthroughSubject<(String, [HighlightPage]?, String?, Int?, String?), Never>()

    var relocateDetails: Relocate? = nil

    init(url: URL, isPDF: Bool = false, cfi: String? = nil, pdfPageNumber: Int? = nil, pdfHighlights: [HighlightPage]? = nil) {
        self.url = url
        self.isPDF = isPDF
        self.initialEBookPosition = cfi
        self.initialPDFPosition = pdfPageNumber

        if self.isPDF || url.lastPathComponent.hasSuffix(".pdf") {
            self.pdfDocument = PDFDocument(url: url) ?? PDFDocument()
            self.pdfView = NoContextMenuPDFView()

            if let pdfHighlights {
                self.addHighlightToPages(highlight: pdfHighlights)
            }

            setTheme()
            setLoading(false)

        } else {
            let config = WKWebViewConfiguration()
            config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
            self.webView = CustomWebView(frame: .zero, configuration: config)
            loadReaderHTML()
        }
    }

    func setBookAnnotations(annotations: [Annotation]) {
        do {
            let jsonAnnotations = try JSONEncoder().encode(annotations)
            let stringJSONAnnotations = String(data: jsonAnnotations, encoding: .utf8) ?? "{}"

            let script = """
                            globalReader?.setAnnotations(\(stringJSONAnnotations))
            """

            guard let webView else {
                return
            }

            webView.evaluateJavaScript(script)

        } catch {
            print("Failed to set annotations")
        }
    }

    /// Moves html from app bundle to documents, to give the webview permissions to read files
    func loadReaderHTML() {
        guard let webView else {
            print("[READERVIEWMODEL] loadReaderHtml: book is a pdf or webview has not been initialized")
            return
        }
        let documentsDir = URL.documentsDirectory
        let newLocation = documentsDir.appendingPathComponent("reader.html")

        guard let readerBundleHtml = Bundle.main.url(forResource: "Web.bundle/reader", withExtension: "html") else {
            print("[READERVIEWMODEL]: READER HTML NOT FOUND")
            return
        }

        do {
            try FileManager.default.copyItem(at: readerBundleHtml, to: newLocation)
        } catch {
            print("[READERVIEWMODEL]: Failed to copy reader html to documents dir")
        }

        webView.loadFileURL(newLocation, allowingReadAccessTo: URL.documentsDirectory)
    }

    /// Loads book
    /// - Parameters:
    ///   - bookPath: The path of the book. Book must be in documents directory of the app
    ///   - bookPosition: Book start position must be book cfi
    func loadBook(bookPath: String, bookPosition: String?, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        guard let webView else {
            print("[READERVIEWMODEL] loadBook: book is a pdf or webview has not been initialized")
            return
        }

        var script: String

        if let position = bookPosition {
            script = """
            globalReader?.initBook("\(bookPath)", "\(position)");
            """
        } else {
            script = """
            globalReader?.initBook("\(bookPath)");
            """
        }

        webView.evaluateJavaScript(script) { success, error in
            completionHandler?(success, error)
        }
    }

    /// Reciver for messages from webiview
    func messageFrom(fromHandler: WebKitMessageHandlers, message: Any) {
        switch fromHandler {
        case .bookRendered:
            setTheme { _, _ in
                self.setHasRenderedBook(rendered: true)
            }
        case .tapHandler:
            if let pointData = message as? [String: Any],
               let x = pointData["x"] as? Double,
               let y = pointData["y"] as? Double
            {
                let point = CGPoint(x: x, y: y)

                tapped.send(point)
            }
        case .selectedText:
            if let rectData = message as? [String: Any],
               let x = rectData["x"] as? Double,
               let y = rectData["y"] as? Double,
               let width = rectData["width"] as? Double,
               let height = rectData["height"] as? Double,
               let text = rectData["text"] as? String
            {
                let selection = Selection(bounds: CGRect(x: x, y: y, width: width, height: height), string: text)
                selectionChanged.send(selection)
            }
        case .relocate:
            if let jsonData = try? JSONSerialization.data(withJSONObject: message),
               let relocateDetails = try? JSONDecoder().decode(Relocate.self, from: jsonData)
            {
                bookRelocated.send(relocateDetails)
                setRelocateDetails(relocateDetails)
            }
        case .didTapHighlight:
            print(message)
        }
    }

    func setTheme(completionHandler: ((Any?, Error?) -> Void)? = nil) {
        if isPDF {
            guard let pdfView else {
                return
            }

            let rgba = getRGBFromHex(hex: theme.bg.rawValue)

            pdfView.backgroundColor = UIColor(red: rgba["red"] ?? 0, green: rgba["green"] ?? 0, blue: rgba["blue"] ?? 0, alpha: 1)
            PDFPageCustomBackground.bg = CGColor(red: rgba["red"] ?? 0, green: rgba["green"] ?? 0, blue: rgba["blue"] ?? 0, alpha: 1)

            setLoading(true)
            pdfView.goToNextPage(nil)
            pdfView.goToPreviousPage(nil)

            theme.save()
            setLoading(false)

        } else {
            guard let webView else {
                print("[READERVIEWMODEL] setTheme: book is a pdf or webview has not been initialized")
                return
            }

            let script = """
            var _style = {
                lineHeight: \(theme.lineHeight),
                justify: \(theme.justify),
                hyphenate: \(theme.hyphenate),
                theme: {bg: "\(theme.bg.rawValue)", fg: "\(theme.fg.rawValue)", name: "\(theme.bg == .dark ? "dark" : "light")"},
                fontSize: \(theme.fontSize),
            }

            var _layout = {
               gap: \(theme.gap),
               maxInlineSize: \(theme.maxInlineSize),
               maxBlockSize: \(theme.maxBlockSize),
               maxColumnCount: \(theme.maxColumnCount),
               flow: \(theme.flow),
            }

            globalReader?.setTheme({style: _style, layout: _layout})
            """

            theme.save()
            webView.evaluateJavaScript(script, completionHandler: completionHandler)
        }
    }

    private var currentSectionHolder = ""
    private var ebookToc: [BookTocItem]?
    private var currentTocItemHolder: BookTocItem?
}

// MARK: Computed Values

extension ReaderViewModel {
    var toc: [BookTocItem]? {
        if isPDF {
            return getPdfToc()
        } else {
            return ebookToc
        }
    }

    var currentTocItem: BookTocItem? {
        guard let toc else {
            return nil
        }

        if isPDF {
            let first = toc.last { tocItem in
                tocItem.outline?.destination?.page?.pageRef?.pageNumber == currentPage?.pageRef?.pageNumber
            }

            if first == nil {
                return currentTocItemHolder
            }

            currentTocItemHolder = first

            return first
        } else {
            return BookTocItem(depth: relocateDetails?.tocItem?.depth ?? 0, label: relocateDetails?.tocItem?.label, href: relocateDetails?.tocItem?.href, chapterId: relocateDetails?.tocItem?.id)
        }
    }

    var currentLabel: String {
        if isPDF {
            pdfCurrentLabel
        } else {
            ebookCurrentLabel
        }
    }

    var pdfCurrentLabel: String {
        let first = toc?.first { tocItem in
            tocItem.outline?.destination?.page?.pageRef?.pageNumber == currentPage?.pageRef?.pageNumber
        }

        if first == nil {
            return currentSectionHolder
        }

        currentSectionHolder = first?.outline?.label ?? ""
        return first?.outline?.label ?? ""
    }

    var ebookCurrentLabel: String {
        relocateDetails?.tocItem?.label ?? ""
    }
}

extension ReaderViewModel {
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func setHasRenderedBook(rendered: Bool) {
        hasRenderedBook = rendered
    }

    func setRelocateDetails(_ relocate: Relocate) {
        relocateDetails = relocate
    }

    func setReaderThemeBackground(_ background: ThemeBackground) {
        theme.bg = background
    }

    /// got to cfi in book or pageIndex in pdf, can only be one or the other
    func goTo(cfi: String? = nil, pageIndex: Int? = nil) {
        if isPDF, let index = pageIndex {
            guard let pdfDocument else {
                print("[READERVIEWMODEL] goTo: no pdfDocument")
                return
            }

            guard let pdfView else {
                print("[READERVIEWMODEL] goTo: no pdfView")
                return
            }

            if let page = pdfDocument.page(at: index) {
                pdfView.go(to: page)
            }
        } else if let cfi {
            guard let webView else {
                print("[READERVIEWMODEL] goTo: webView not intiliazed")
                return
            }

            let setPositionScript = """
                   globalReader?.view.goTo("\(cfi)")
            """

            webView.evaluateJavaScript(setPositionScript) { _, _ in }
        } else {
            print("[READERVIEWMODEL] goTo: Going nowhere")
        }
    }
}

extension ReaderViewModel {
    func pdfPageChanged() {
        guard let pdfView else {
            return
        }

        currentPage = pdfView.currentPage

        // Disable popup menu
        pdfView.disableMenuInteractions()

        guard let page = pdfView.currentPage else {
            print("[READERVIEWMODEL] pdfPageChanged: No page")
            return
        }

        pdfRelocated.send(page)
    }

    func addHighlightToPages(highlight: [HighlightPage]) {
        highlight.forEach { highlightPageLocation in
            guard let highlightPage = self.pdfDocument?.page(at: highlightPageLocation.page - 1) else { return }

            highlightPageLocation.ranges.forEach { highlightPageRange in
                guard let highlightSelection = self.pdfDocument?.selection(from: highlightPage, atCharacterIndex: highlightPageRange.lowerBound, to: highlightPage, atCharacterIndex: highlightPageRange.upperBound)
                else { return }

                highlightSelection.selectionsByLine().forEach { hightlightSelectionByLine in
                    let annotation = PDFAnnotation(
                        bounds: hightlightSelectionByLine.bounds(for: highlightPage),
                        forType: .highlight,
                        withProperties: nil
                    )

                    annotation.endLineStyle = .square
                    annotation.color = UIColor.yellow.withAlphaComponent(1)
                    highlightPage.addAnnotation(annotation)
                    self.pdfView?.clearSelection()
                }
            }
        }
    }

    func selectionDidChange() {
        selectionChanged.send(nil)
    }

    // pdf - https://github.com/drearycold/YetAnotherEBookReader/blob/main/YetAnotherEBookReader/Views/PDFView/YabrPDFView.swift#L453
    func highlightSelection() {
        if isPDF {
            guard let pdfView else {
                return
            }

            guard let currentSelection = pdfView.currentSelection else {
                return
            }

            // single highlight but possible to highlight between multiple pages
            // save this as a highlight
            var pdfHighlightPageLocations = [HighlightPage]()

            currentSelection.pages.forEach { selectionPage in
                guard let selectionPageNumber = selectionPage.pageRef?.pageNumber else { return }
                var pdfHighlightPage = HighlightPage(page: selectionPageNumber, ranges: [])
                for i in 0 ..< currentSelection.numberOfTextRanges(on: selectionPage) {
                    let selectionPageRange = currentSelection.range(at: i, on: selectionPage)

                    pdfHighlightPage.ranges.append(selectionPageRange)
                }

                pdfHighlightPageLocations.append(pdfHighlightPage)
            }

            addHighlightToPages(highlight: pdfHighlightPageLocations)

            let selectedString = currentSelection.string ?? ""
            highlighted.send((selectedString, pdfHighlightPageLocations, nil, nil, nil))

        } else {
            guard let webView else {
                return
            }
            // TODO: make into a function inside the reader

            let script = """
            var range = getSelectionRange(globalReader?.doc);
            if (!range) return
            var selectionString = range?.toString()
            var cfi = globalReader.view.getCFI(globalReader.index, range);
            var promise = globalReader.view.addAnnotation({value: cfi, color: "#FFFF00" });
            var chap = await promise;

            globalReader?.annotationsByValue.set(
                  cfi,
                  {
                    index: chap.index,
                    range: range,
                    value: cfi,
                    pos: getPosition(range),
                    text: range.toString(),
                    color: "#FFFF00"
                  }
            );


            return {index: chap.index, label: chap.label, cfi: cfi, text: selectionString};
            """

            webView.callAsyncJavaScript(script, in: nil, in: .page) { result in

                switch result {
                case .success(let success):
                    if let data = success as? [String: Any],
                       let index = data["index"] as? Int,
                       let label = data["label"] as? String,
                       let cfi = data["cfi"] as? String,
                       let text = data["text"] as? String
                    {
                        self.highlighted.send((text, nil, cfi, index, label))
                    }

                case .failure(let error):
                    print("EBOOK highlightSelection error: \(error.localizedDescription)")
                }

                self.clearWebViewSelection()
            }
        }
    }

    func copySelection() {
        if isPDF {
            guard let pdfView else {
                print("NO PDF VIEW")
                return
            }

            let selections = pdfView.currentSelection?.string
            guard let text = selections else {
                return
            }
            UIPasteboard.general.setValue(text, forPasteboardType: UTType.plainText.identifier)
            pdfView.clearSelection()
        } else {
            let script = """
            globalReader?.doc?.getSelection()?.toString()
            """

            webView?.evaluateJavaScript(script, completionHandler: { success, error in
                if let success {
                    UIPasteboard.general.setValue(success as! String, forPasteboardType: UTType.plainText.identifier)

                    self.clearWebViewSelection()
                }

                if let error {
                    print(error)
                }
            })
        }
    }

    private func clearWebViewSelection() {
        guard let webView else {
            return
        }
        let script = """
        globalReader?.doc?.getSelection()?.removeAllRanges();
        """

        webView.evaluateJavaScript(script)
    }
}

extension ReaderViewModel {
    func getPdfToc() -> [BookTocItem]? {
        guard let pdfDocument else {
            return nil
        }

        var toc = [BookTocItem]()
        if let root = pdfDocument.outlineRoot {
            var stack: [(outline: PDFOutline, depth: Int)] = [(root, -1)]
            while !stack.isEmpty {
                let (current, depth) = stack.removeLast()
                if let label = current.label, !label.isEmpty {
//                    toc.append(PDFTocItem(outline: current, depth: depth))
                    toc.append(BookTocItem(depth: depth, outline: current))
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

    func setEbookToc() {
        guard let webView else {
            print("[READERVIEWMODEL] setEbookToc: NO WEBVIEW ")
            return
        }

        let script = """
         function flattenTocItems(items) {
           const flattenedItems = []

           function flatten(item, depth) {
             const flattenedItem = {
               href: item.href,
               id: item.id,
               label: item.label,
               depth: depth
             }

             flattenedItems.push(flattenedItem)

             if (item.subitems && item.subitems.length > 0) {
               item.subitems.forEach(subitem => flatten(subitem, depth + 1))
             }
           }

           items.forEach(item => flatten(item, 0))

          return flattenedItems
        }

        JSON.stringify(flattenTocItems(globalReader?.book?.toc));
        """

        webView.evaluateJavaScript(script) { success, error in

            if let content = success as? String {
                if let data = content.data(using: .utf8) {
                    do {
                        let toc = try JSONDecoder().decode([EBookTocItem].self, from: data)

                        self.ebookToc = toc.map { item in
                            BookTocItem(depth: item.depth, label: item.label, href: item.href, chapterId: item.id)
                        }

                    } catch {
                        print("[READERVIEWMODEL] setEbookToc: Failed to decode: \(error.localizedDescription)")
                    }
                }
            }

            if let error {
                print("[READERVIEWMODEL] setEbookToc: \(error.localizedDescription)")
            }
        }
    }

    func isBookTocItemSelected(item: BookTocItem) -> Bool {
        let selected = item.id == (relocateDetails?.tocItem?.id ?? 0)
        let pdfSelected = isPDF && item.outline?.hashValue == currentTocItem?.outline?.hashValue

        return selected || pdfSelected
    }
}
