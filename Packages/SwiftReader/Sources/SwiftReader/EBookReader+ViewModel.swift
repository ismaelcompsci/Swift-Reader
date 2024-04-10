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

public enum EBookReaderError: Error {
    case renderError(Error)
    case serverError(String)
}

public enum EBookReaderState {
    case loading
    case done // do nothing whehn done
    case failure(EBookReaderError)
}

// server: https://github.com/readium/swift-toolkit/blob/develop/Sources/Adapters/GCDWebServer/GCDHTTPServer.swift
public class EBookReaderViewModel: ObservableObject {
    let webView: NoContextMenuWebView
    let server: FileServer
    var bookFile: URL

    ///  delay in milliseconds
    let delay: Duration?

    /// initial position to open the book at
    var openCfi: String?

    @Published public var state: EBookReaderState = .loading

    @Published public var toc: [EBookTocItem]? = nil
    @Published public var currentLocation: Relocate? = nil
    @Published public var currentLabel: String = ""

    @Published public var theme = BookTheme()

    @Published public var hasFinishedLoadingJS = false { didSet { startIfReady() }} // I need to do some work when all three bools are true
    @Published private(set) var isServerStarted = false { didSet { startIfReady() }} // only when all three are true can i render the book
    @Published private(set) var initatedSwiftReader = false { didSet { startIfReady() }} //
    @Published public private(set) var renderedBook = false
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

    public var onTappedHighlight = PassthroughSubject<TappedHighlight, Never>()
    public var onTapped = PassthroughSubject<CGPoint, Never>()
    public var onSelectionChanged = PassthroughSubject<Selection?, Never>()
    public var onRelocated = PassthroughSubject<Relocate, Never>()
    /// 0 text, 1 cfi,  2 index, 3 label
    public var onHighlighted = PassthroughSubject<(String, String?, Int?, String?), Never>()

    public var currentTocItem: RelocateTocItem? {
        currentLocation?.tocItem
    }

    var allDone: Bool {
        isServerStarted && initatedSwiftReader && renderedBook && didSetTheme && finishedSettingUpBook && hasFinishedLoadingJS
    }

    public init(file: URL, delay: Duration? = nil, startCfi: String? = nil) {
        self.server = FileServer.sharedInstance
        self.webView = NoContextMenuWebView.shared
        self.bookFile = file
        self.delay = delay
        self.openCfi = startCfi

        setupServer { [weak self] in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                let started = try? self.server.start()
                self.isServerStarted = started ?? false

                if let started = started, started == false {
                    self.state = .failure(.serverError("Could not start web server."))
                    return
                }

                self.loadUrl(url: URL(string: self.server.base)!)
            }
        }
    }

    private var renderTaskHasStarted = false
    private func startIfReady() {
        let start = isServerStarted && initatedSwiftReader && hasFinishedLoadingJS
        if start == true && renderedBook == false && renderTaskHasStarted == false {
            Task {
                renderTaskHasStarted = true
                await self.startReader()
            }
        }
    }

    func setupServer(completion: @escaping () -> Void) {
        let scriptDir = Bundle.module.path(forResource: "scripts", ofType: nil)

        guard let scriptDir else {
            print("there is no scripts dir in bundle")
            return
        }

        let backgroundQueue = DispatchQueue(
            label: "background_queue",
            qos: .background
        )

        backgroundQueue.async { [weak self] in

            guard let self = self else {
                return
            }

            // DO IN BACKGROUND THREAD
            if self.server.server.isRunning {
                self.server.server.stop()

                self.server.server.removeAllHandlers()
            }

            self.server.registerGETHandlerForDirectory("/", directoryPath: scriptDir, indexFilename: "reader.html")
            self.server.registerHandlerForMethod("GET", module: "api", resource: "book", handler: self.getBookHandler)

            completion()
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

                onTapped.send(point)
            }
        case .selectedText:
            if let rectData = message as? [String: Any],
               let x = rectData["x"] as? Double,
               let y = rectData["y"] as? Double,
               let width = rectData["width"] as? Double,
               let height = rectData["height"] as? Double,
               let text = rectData["text"] as? String,
               let dir = rectData["dir"] as? String
            {
                let selection = Selection(bounds: CGRect(x: x, y: y, width: width, height: height), string: text, dir: dir)
                onSelectionChanged.send(selection)
            }
        case .relocate:

            if let jsonData = try? JSONSerialization.data(withJSONObject: message),
               let relocateDetails = try? JSONDecoder().decode(Relocate.self, from: jsonData)
            {
                onRelocated.send(relocateDetails)
                currentLocation = relocateDetails
                currentLabel = relocateDetails.tocItem?.label ?? ""
            }

        case .didTapHighlight:
            if let json = try? JSONSerialization.data(withJSONObject: message),
               let highlight = try? JSONDecoder().decode(TappedHighlight.self, from: json)
            {
                onTappedHighlight.send(highlight)
            }
        }
    }

    public func setBookTheme() {
        theme.save()

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
           margin: \(theme.margin)
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

        let ext = bookFile.pathExtension

        if let openCfi {
            args = "`\(server.base)/api/book`, `\(openCfi)`, `.\(ext)`"
        } else {
            args = "`\(server.base)/api/book`, undefined, `.\(ext)`"
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
            state = .failure(.renderError(error))
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

    @MainActor
    public func getToc() async -> [EBookTocItem]? {
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


         JSON.stringify(flattenTocItems(globalReader?.book?.toc ?? []));
        """

        let stringToc = try? await (webView.evaluateJavaScript(script) as! String?)
        let data = stringToc?.data(using: .utf8)

        guard let data else {
            return nil
        }

        let toc = try? JSONDecoder().decode([EBookTocItem].self, from: data)

        return toc
    }

    public func setBookAnnotations(annotations: [Annotation]) {
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

    public func clearWebViewSelection() {
        let script = """
        globalReader?.doc?.getSelection()?.removeAllRanges();
        """

        webView.evaluateJavaScript(script)
    }

    public func isBookTocItemSelected(item: EBookTocItem) -> Bool {
        item.id == (currentLocation?.tocItem?.id ?? -1)
    }

    public func hasSelection() async throws -> Bool {
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

// actions
public extension EBookReaderViewModel {
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
                    self.onHighlighted.send((text, cfi, index, label))
                }

            case .failure(let error):
                print("highlightSelection error: \(error.localizedDescription)")
            }

            self.clearWebViewSelection()
        }
    }

    func getSelection(completionHandler: @escaping (_ text: String?) -> Void) {
        let script = """
        globalReader?.doc?.getSelection()?.toString()
        """

        webView.evaluateJavaScript(script, completionHandler: { success, _ in

            if let success, let text = success as? String {
                completionHandler(text)
            } else {
                completionHandler(nil)
            }

        })
    }

    func copySelection() {
        getSelection { text in
            if let text {
                self.setPastboardText(with: text)

                self.clearWebViewSelection()
            }
        }
    }

    func setPastboardText(with text: String) {
        UIPasteboard.general.setValue(text, forPasteboardType: UTType.plainText.identifier)
    }

    /// value is highlight cfi range
    func removeHighlight(_ value: String) {
        let script = """
        globalReader?.view.addAnnotation(
        {
            value: "\(value)",
        },
        true
        )
        """

        webView.evaluateJavaScript(script)
    }
}
