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

    @Published var currentTocItem: BookTocItem? = nil
    @Published var currentLabel: String = ""
    @Published var showSettingsSheet = false
    @Published var doneWithInitalLoading = false
    @Published var showContentSheet = false
    @Published var relocateDetails: Relocate? = nil
    @Published var theme = Theme()
    @Published var currentPage: PDFPage?
    @Published var hasRenderedBook = false { didSet {
        setEbookToc()
    }}
    @Published var isLoading = true {
        didSet {
            if isLoading == false && !hasRenderedBook && !isPDF {
                loadBook(bookPath: url.absoluteString, bookPosition: initialEBookPosition)
            }
        }
    }

    // MARK: Events

    var bookRelocated = PassthroughSubject<Relocate, Never>()
    var pdfRelocated = PassthroughSubject<PDFPage, Never>()
    var tapped = PassthroughSubject<CGPoint, Never>()
    var selectionChanged = PassthroughSubject<Selection?, Never>()
    /// 0 text, 1 pdfHighlight, 2 cfi,  3 index, 4 label
    var highlighted = PassthroughSubject<(String, [HighlightPage]?, String?, Int?, String?), Never>()

    init(url: URL, isPDF: Bool = false, cfi: String? = nil, pdfPageNumber: Int? = nil) {
        self.url = url
        self.isPDF = isPDF
        self.initialEBookPosition = cfi
        self.initialPDFPosition = pdfPageNumber

        if self.isPDF || url.lastPathComponent.hasSuffix(".pdf") {
            self.pdfDocument = PDFDocument(url: url) ?? PDFDocument()
            self.pdfView = NoContextMenuPDFView()

            setTheme()
        } else {
            let config = WKWebViewConfiguration()
            config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
            self.webView = CustomWebView(frame: .zero, configuration: config)
            loadReaderHTML()
        }
    }

    deinit {
        print("DE INITINTG THING")
    }

    /// Moves html from app bundle to documents, to give the webview permissions to read files
    private func loadReaderHTML() {
        guard let webView else {
            print("[ReaderViewModel] loadReaderHtml: book is a pdf or webview has not been initialized")
            return
        }
        let documentsDir = URL.documentsDirectory
        let newLocation = documentsDir.appendingPathComponent("reader.html")

        guard let readerBundleHtml = Bundle.main.url(forResource: "Web.bundle/reader", withExtension: "html") else {
            print("[ReaderViewModel]: READER HTML NOT FOUND")
            return
        }

        do {
            try FileManager.default.copyItem(at: readerBundleHtml, to: newLocation)
        } catch {
            print("[ReaderViewModel]: Failed to copy reader html to documents dir - \(error.localizedDescription)")
        }

        webView.loadFileURL(newLocation, allowingReadAccessTo: URL.documentsDirectory)
    }

    /// Loads book
    /// - Parameters:
    ///   - bookPath: The path of the book. Book must be in documents directory of the app
    ///   - bookPosition: Book start position must be book cfi
    private func loadBook(bookPath: String, bookPosition: String?, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        guard let webView else {
            print("[ReaderViewModel] loadBook: book is a pdf or webview has not been initialized")
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
            print("[ReaderViewModel] setBookAnnotations: Failed to set annotations - \(error.localizedDescription)")
        }
    }

    /// Reciver for messages from webiview
    func messageFrom(fromHandler: WebKitMessageHandlers, message: Any) {
        switch fromHandler {
        case .bookRendered:
            setTheme { _, _ in
                self.setHasRenderedBook(rendered: true)

                Task {
                    try? await Task.sleep(nanoseconds: 1000000000 / 2)

                    DispatchQueue.main.async {
                        self.doneWithInitalLoading = true
                    }
                }
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
                setRelocateDetails(relocateDetails)
                currentTocItem = getEBookCurrentTocItem()
                setEBookCurrentLabel()
                bookRelocated.send(relocateDetails)
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
                print("[ReaderViewModel] setTheme: book is a pdf or webview has not been initialized")
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

    func pdfPageChanged() {
        guard let pdfView else {
            return
        }

        currentPage = pdfView.currentPage

        // Disable popup menu
        pdfView.disableMenuInteractions()

        guard let page = pdfView.currentPage else {
            print("[ReaderViewModel] pdfPageChanged: No page")
            return
        }

        currentTocItem = getPDFCurrentTocItem(from: page)
        setPDFCurrentLabel(from: page)

        pdfRelocated.send(page)
    }

    func selectionDidChange() {
        selectionChanged.send(nil)
    }

    private var currentSectionHolder = ""
    private var ebookToc: [BookTocItem]?
    private var currentTocItemHolder: BookTocItem?
}

extension ReaderViewModel {
    var toc: [BookTocItem]? {
        if isPDF {
            return getPdfToc()
        } else {
            return ebookToc
        }
    }

    private func getPDFCurrentTocItem(from: PDFPage) -> BookTocItem? {
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

    private func getEBookCurrentTocItem() -> BookTocItem {
        return BookTocItem(depth: relocateDetails?.tocItem?.depth ?? 0, label: relocateDetails?.tocItem?.label, href: relocateDetails?.tocItem?.href, chapterId: relocateDetails?.tocItem?.id)
    }
}

extension ReaderViewModel {
    func setPDFCurrentLabel(from page: PDFPage) {
        let first = toc?.first { tocItem in
            tocItem.outline?.destination?.page?.pageRef?.pageNumber == page.pageRef?.pageNumber
        }

        if first == nil {
            currentLabel = currentSectionHolder
            return
        }

        currentSectionHolder = first?.outline?.label ?? ""
        currentLabel = first?.outline?.label ?? ""
    }

    func setEBookCurrentLabel() {
        currentLabel = relocateDetails?.tocItem?.label ?? ""
    }

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
}

extension ReaderViewModel {
    // pdf - https://github.com/drearycold/YetAnotherEBookReader/blob/main/YetAnotherEBookReader/Views/PDFView/YabrPDFView.swift#L453
    func highlightSelection() {
        if isPDF {
            guard let pdfView else {
                print("[ReaderViewModel] highlightSelection: no pdf view")
                return
            }

            guard let currentSelection = pdfView.currentSelection else {
                print("[ReaderViewModel] highlightSelection: no selection")
                return
            }

            // single highlight but possible to highlight between multiple pages
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
                print("[ReaderViewModel] highlightSelection: no webview")
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
                    print("[ReaderViewModel] highlightSelection error: \(error.localizedDescription)")
                }

                self.clearWebViewSelection()
            }
        }
    }

    func copySelection() {
        if isPDF {
            guard let pdfView else {
                print("[ReaderViewModel] NO PDF VIEW")
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
                    print("[ReaderViewModel] copySelection: \(error)")
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
    private func getPdfToc() -> [BookTocItem]? {
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

    private func setEbookToc() {
        guard let webView else {
            print("[ReaderViewModel] setEbookToc: NO WEBVIEW ")
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
                        print("[ReaderViewModel] setEbookToc: Failed to decode: \(error.localizedDescription)")
                    }
                }
            }

            if let error {
                print("[ReaderViewModel] setEbookToc: \(error.localizedDescription)")
            }
        }
    }
}

extension ReaderViewModel {
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

    func isBookTocItemSelected(item: BookTocItem) -> Bool {
        let selected = item.id == (relocateDetails?.tocItem?.id ?? 0)
        let pdfSelected = isPDF && item.outline?.hashValue == currentTocItem?.outline?.hashValue

        return selected || pdfSelected
    }

    func hasSelection() async throws -> Bool {
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Bool, Error>) in
            guard let webView = self.webView else {
                print("[READERVIEWMODEL] hasSelection: no webView")
                continuation.resume(returning: false)
                return
            }

            let script = """
            function test() {
            const sel = globalReader?.doc?.getSelection();
              if (!sel.rangeCount) return false;
              const range = sel.getRangeAt(0);
              if (range.collapsed) return false;
              return true;
            }

            !!test();
            """

            DispatchQueue.main.async {
                webView.evaluateJavaScript(script, completionHandler: { result, error in
                    if let error = error {
                        print("Error evaluating JavaScript: \(error)")
                        continuation.resume(throwing: error)
                    } else if let success = result as? Bool {
                        continuation.resume(returning: success)
                    } else {
                        let unexpectedError = NSError(domain: "YourDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unexpected result type"])
                        continuation.resume(throwing: unexpectedError)
                    }
                })
            }
        }
    }
}
