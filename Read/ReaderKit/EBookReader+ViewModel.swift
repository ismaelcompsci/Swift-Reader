//
//  EBookReader+ViewModel.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import Combine
import GCDWebServers
import SwiftUI
import UniformTypeIdentifiers
import WebKit

class EBookReaderViewModel: ObservableObject {
    let webView: NoContextMenuWebView
    let server: FileServer
    var bookFile: URL

    ///  delay in milliseconds
    let delay: Duration?

    /// initial position to open the book at
    var openCfi: String?

    @Published var toc: [EBookTocItem]? = nil
    @Published var currentLocation: Relocate? = nil
    @Published var currentLabel: String = ""

    var currentTocItem: RelocateTocItem? {
        currentLocation?.tocItem
    }

    @Published var theme = Theme()

    @Published var hasFinishedLoadingJS = false
    @Published private(set) var isServerStarted = false
    @Published private(set) var initatedSwiftReader = false
    @Published private(set) var renderedBook = false
    @Published private(set) var finishedSettingUpBook = false
    @Published private(set) var didSetTheme = false {
        didSet {
            Task {
                // added delay makes it so there is no white flash
                if let delay {
                    try? await Task.sleep(for: delay)

                    DispatchQueue.main.sync {
                        self.finishedSettingUpBook = true
                    }
                } else {
                    finishedSettingUpBook = true
                }
            }
        }
    }

    var tapped = PassthroughSubject<CGPoint, Never>()
    var selectionChanged = PassthroughSubject<Selection?, Never>()
    var bookRelocated = PassthroughSubject<Relocate, Never>()
    /// 0 text, 1 cfi,  2 index, 3 label
    var highlighted = PassthroughSubject<(String, String?, Int?, String?), Never>()

    var canStartReader: Bool {
        isServerStarted && initatedSwiftReader && hasFinishedLoadingJS
    }

    var allDone: Bool {
        isServerStarted && initatedSwiftReader && renderedBook && didSetTheme && finishedSettingUpBook && hasFinishedLoadingJS
    }

    init(file: URL, delay: Duration? = nil) {
        self.server = FileServer.sharedInstance
        self.bookFile = file
        self.delay = delay
        self.webView = NoContextMenuWebView.shared

        setupServer()

        loadUrl(url: URL(string: server.base)!)
    }

    init(file: URL, delay: Duration? = nil, startCfi: String) {
        self.server = FileServer.sharedInstance
        self.webView = NoContextMenuWebView.shared
        self.bookFile = file
        self.delay = delay
        self.openCfi = startCfi

        setupServer()
        loadUrl(url: URL(string: server.base)!)
    }

    func setupServer() {
        let scriptDir = Bundle.main.path(forResource: "scripts", ofType: nil)

        guard let scriptDir else {
            print("there is no scripts dir in bundle")
            return
        }

        if server.server.isRunning {
            server.server.stop()

            server.server.removeAllHandlers()
        }

        server.registerGETHandlerForDirectory("/", directoryPath: scriptDir, indexFilename: "reader.html")
        server.registerHandlerForMethod("GET", module: "api", resource: "book", handler: getBookHandler)

        do {
            try server.start()
            isServerStarted = true

        } catch {
            print("Failed to start server: \(error.localizedDescription)")
        }
    }

    // handler for http request
    private func getBookHandler(_ req: GCDWebServerRequest?) -> GCDWebServerDataResponse? {
        let data = try? Data(contentsOf: bookFile)

        guard let data else {
            print("Failed to read data from book url")
            return nil
        }

        return GCDWebServerDataResponse(data: data, contentType: "application/octet-stream")
    }

    private func loadUrl(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func messageFrom(fromHandler: BookWebViewMessageHandlers, message: Any) {
        switch fromHandler {
        case .initiatedSwiftReader:
            initatedSwiftReader = true
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
                currentLocation = relocateDetails
                currentLabel = relocateDetails.tocItem?.label ?? ""
            }

        case .didTapHighlight:
            print(message)
        }
    }

    func setBookTheme() {
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
           animated: \(theme.animated),
        }

        globalReader?.setTheme({style: _style, layout: _layout})
        """

        webView.evaluateJavaScript(script) { success, error in
            if let error {
                print("ERROR setting book theme: \(error)")
            }

            if success != nil {
                print("DONE SETTING THEME")

                if !self.didSetTheme {
                    self.didSetTheme = true
                }
            }
        }
    }

    @MainActor
    private func renderBook() async {
        var args: String

        if let openCfi {
            args = "`\(server.base)/api/book`, `\(openCfi)`"
        } else {
            args = "`\(server.base)/api/book`"
        }

        let script = """
        var initPromise =  globalReader?.initBook(\(args))

        await initPromise

        return initPromise
        """

        do {
            _ = try await webView.callAsyncJavaScript(script, contentWorld: .page)
            renderedBook = true

        } catch {
            print("Failed to initate book: \(error.localizedDescription)")
        }
    }

    @MainActor
    func startReader() async {
        await renderBook()
        let tocItems = await getToc()
        if toc == nil {
            toc = tocItems
        }

        setBookTheme()
    }

    func goTo(cfi: String) {
        let script = """
        globalReader?.view.goTo("\(cfi)")
        """

        webView.evaluateJavaScript(script)
    }

    func goToFraction(position: Double) {
        let script = """
        globalReader?.view.goToFraction(\(position))
        """

        webView.evaluateJavaScript(script)
    }

    @MainActor
    func getToc() async -> [EBookTocItem]? {
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

        let stringToc = try? await (webView.evaluateJavaScript(script) as! String?)
        let data = stringToc?.data(using: .utf8)

        guard let data else {
            return nil
        }

        let toc = try? JSONDecoder().decode([EBookTocItem].self, from: data)

        return toc
    }

    func copySelection() {
        let script = """
        globalReader?.doc?.getSelection()?.toString()
        """

        webView.evaluateJavaScript(script, completionHandler: { success, error in
            if let success {
                UIPasteboard.general.setValue(success as! String, forPasteboardType: UTType.plainText.identifier)

                self.clearWebViewSelection()
            }

            if let error {
                print("copySelection: \(error)")
            }
        })
    }

    func setBookAnnotations(annotations: [Annotation]) {
        do {
            let jsonAnnotations = try JSONEncoder().encode(annotations)
            let stringJSONAnnotations = String(data: jsonAnnotations, encoding: .utf8) ?? "{}"

            let script = """
                            globalReader?.setAnnotations(\(stringJSONAnnotations))
            """

            webView.evaluateJavaScript(script)

        } catch {
            print("[ReaderViewModel] setBookAnnotations: Failed to set annotations - \(error.localizedDescription)")
        }
    }

    func highlightSelection() {
        let script = """
        var hPromise = globalReader?.makeHighlight()

        await hPromise
        return hPromise
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
                    self.highlighted.send((text, cfi, index, label))
                }

            case .failure(let error):
                print("highlightSelection error: \(error.localizedDescription)")
            }

            self.clearWebViewSelection()
        }
    }

    func clearWebViewSelection() {
        let script = """
        globalReader?.doc?.getSelection()?.removeAllRanges();
        """

        webView.evaluateJavaScript(script)
    }

    func isBookTocItemSelected(item: EBookTocItem) -> Bool {
        item.id == (currentLocation?.tocItem?.id ?? -1)
    }

    func hasSelection() async throws -> Bool {
        let script = """
        function test() {
        const sel = globalReader?.doc?.getSelection();
          if (!sel.rangeCount) return false;
          const range = sel.getRangeAt(0);
          if (range.collapsed) return false;
          return true;
        }

        return !!test();
        """

        let hasSelectionResponse = try? await webView.callAsyncJavaScript(script, in: nil, contentWorld: .page)
        let hasSelection = hasSelectionResponse as? Bool

        return hasSelection ?? false
    }
}

extension EBookReaderViewModel {
    func reset() {
        renderedBook = false
        finishedSettingUpBook = false
        didSetTheme = false

        let script = """
        globalReader?.view?.remove()
        """

        webView.evaluateJavaScript(script)
    }
}
