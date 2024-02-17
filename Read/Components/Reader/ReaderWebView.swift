//
//  ReaderWebView.swift
//  Read
//
//  Created by Mirna Olvera on 2/5/24.
//

import Foundation
import SwiftUI
import WebKit

class ReaderWebViewCoordinator: NSObject, WKNavigationDelegate {
    var viewModel: ReaderViewModel

    init(viewModel: ReaderViewModel) {
        self.viewModel = viewModel
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewModel.setLoading(false)
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        viewModel.setLoading(false)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        viewModel.setLoading(false)
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        viewModel.setLoading(true)
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        viewModel.setLoading(true)
    }
}

extension ReaderWebViewCoordinator: WKUIDelegate {
    @available(iOS 16.0, *)
    func webView(_ webView: WKWebView, willPresentEditMenuWithAnimator animator: UIEditMenuInteractionAnimating) {}
}

extension ReaderWebViewCoordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let handlerCase = WebKitMessageHandlers(rawValue: message.name) {
            viewModel.messageFrom(fromHandler: handlerCase,
                                  message: message.body)
        }
    }
}

class CustomWebView: WKWebView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override func buildMenu(with builder: UIMenuBuilder) {
        if #available(iOS 16.0, *) {
            builder.remove(menu: .lookup)
            builder.remove(menu: .file)
            builder.remove(menu: .edit)
            builder.remove(menu: .view)
            builder.remove(menu: .window)
            builder.remove(menu: .help)
            builder.remove(menu: .about)
            builder.remove(menu: .preferences)
            builder.remove(menu: .services)
            builder.remove(menu: .hide)
            builder.remove(menu: .quit)
            builder.remove(menu: .newScene)
            builder.remove(menu: .openRecent)
            builder.remove(menu: .close)
            builder.remove(menu: .print)
            builder.remove(menu: .document)
            builder.remove(menu: .undoRedo)
            builder.remove(menu: .standardEdit)
            builder.remove(menu: .find)
            builder.remove(menu: .replace)
            builder.remove(menu: .share)
            builder.remove(menu: .textStyle)
            builder.remove(menu: .spelling)
            builder.remove(menu: .spellingPanel)
            builder.remove(menu: .spellingOptions)
            builder.remove(menu: .substitutions)
            builder.remove(menu: .substitutionsPanel)
            builder.remove(menu: .substitutionOptions)
            builder.remove(menu: .transformations)
            builder.remove(menu: .speech)
            builder.remove(menu: .learn)
            builder.remove(menu: .format)
            builder.remove(menu: .font)
            builder.remove(menu: .textSize)
            builder.remove(menu: .textColor)
            builder.remove(menu: .textStylePasteboard)
            builder.remove(menu: .text)
            builder.remove(menu: .writingDirection)
            builder.remove(menu: .alignment)
            builder.remove(menu: .toolbar)
            builder.remove(menu: .sidebar)
            builder.remove(menu: .fullscreen)
            builder.remove(menu: .minimizeAndZoom)
            builder.remove(menu: .bringAllToFront)
        }

        super.buildMenu(with: builder)
    }
}

struct ReaderWebView: UIViewRepresentable {
    typealias UIViewType = CustomWebView

    var vm: ReaderViewModel

    init(viewModel: ReaderViewModel) {
        self.vm = viewModel
    }

    func makeUIView(context: Context) -> CustomWebView {
        guard let webView = vm.webView else {
            print("no web view")

            return CustomWebView()
        }

        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        let userContentController = webView
            .configuration
            .userContentController

        userContentController.removeAllScriptMessageHandlers()

        let source = "function captureLog(msg) { window.webkit.messageHandlers.readerHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        userContentController.add(LoggingMessageHandler(), name: "readerHandler")

        userContentController.add(context.coordinator,
                                  name: WebKitMessageHandlers.bookRendered.rawValue)

        userContentController.add(context.coordinator,
                                  name: WebKitMessageHandlers.tapHandler.rawValue)

        userContentController.add(context.coordinator,
                                  name: WebKitMessageHandlers.selectedText.rawValue)

        userContentController.add(context.coordinator,
                                  name: WebKitMessageHandlers.relocate.rawValue)

        // TODO: Remove
        webView.isInspectable = true

        return webView
    }

    func updateUIView(_ uiView: CustomWebView, context: Context) {}

    func makeCoordinator() -> ReaderWebViewCoordinator {
        return ReaderWebViewCoordinator(viewModel: vm)
    }
}

enum WebKitMessageHandlers: String {
    case bookRendered
    case tapHandler
    case selectedText
    case relocate
}

//
// class EBookReaderViewModel: ObservableObject {
//    var webView: CustomWebView
//
//    @Published var isLoading = true
//
//    @Published var hasLoadedBook = false
//    @Published var hasRenderedBook = false
//
//    @Published var showMenuOverlay = false
//    @Published var showSettingsSheet = false
//    @Published var showContentSheet = false
//
//    @Published var relocateDetails: Relocate? = nil
//
//    @Published var theme = Theme()
//
//    @Published var bookToc: [TocItem]? = nil
//
//    var currentLabel: String {
//        relocateDetails?.tocItem?.label ?? ""
//    }
//
//    init() {
//        let config = WKWebViewConfiguration()
//        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
//
//        self.webView = CustomWebView(frame: .zero, configuration: config)
//        loadReaderHtml()
//    }
//
//    func setLoading(_ loading: Bool) {
//        isLoading = loading
//    }
//
//    func setHasRenderedBook(_ renderedBook: Bool) {
//        hasRenderedBook = renderedBook
//    }
//
//    func setReaderThemeBackground(_ background: ThemeBackground) {
//        theme.bg = background
//    }
//
//    func setRelocateDetails(_ relocate: Relocate) {
//        relocateDetails = relocate
//    }
//
//    func setReaderPosistion(cfi: String? = nil) {
//        if let cfi = cfi {
//            let setPositionScript = """
//                   globalReader?.view.goTo("\(cfi)")
//            """
//
//            webView.evaluateJavaScript(setPositionScript) { _, _ in
//            }
//        }
//    }
//
//    func handleTap(_ point: CGPoint) {
//        withAnimation {
//            showMenuOverlay.toggle()
//        }
//    }
//
//    func messageFrom(fromHandler: WebKitMessageHandlers, message: Any) {
//        switch fromHandler {
//        case .bookRendered:
//            setTheme { _, _ in
//                self.setHasRenderedBook(true)
//            }
//
//        case .tapHandler:
//            print(message)
//            if let pointData = message as? [String: Any],
//               let x = pointData["x"] as? Double,
//               let y = pointData["y"] as? Double
//            {
//                let point = CGPoint(x: x, y: y)
//
//                handleTap(point)
//            }
//        case .selectedText:
//            break
////            print(message)
//        case .relocate:
//            if let jsonData = try? JSONSerialization.data(withJSONObject: message),
//               let relocateDetails = try? JSONDecoder().decode(Relocate.self, from: jsonData)
//            {
//                setRelocateDetails(relocateDetails)
//            }
//        }
//    }
//
//    func loadReaderHtml() {
//        let documentsDir = URL.documentsDirectory
//        let newLocation = documentsDir.appendingPathComponent("reader.html")
//
//        guard let readerBundleHtml = Bundle.main.url(forResource: "Web.bundle/reader", withExtension: "html") else {
//            print("READER HTML NOT FOUND")
//            return
//        }
//
//        do {
//            try FileManager.default.copyItem(at: readerBundleHtml, to: newLocation)
//        } catch {
//            print("Failed to copy reader html to documents dir")
//        }
//
//        webView.loadFileURL(newLocation, allowingReadAccessTo: URL.documentsDirectory)
//    }
//
//    func loadBook(_ book: Book, completionHandler: ((Any?, Error?) -> Void)? = nil) {
//        guard let bookPath = book.bookPath else {
//            return
//        }
//
//        let fullBookPath = URL.documentsDirectory.appending(path: bookPath)
//
//        var script: String
//
//        if let position = book.readingPosition?.epubCfi {
//            script = """
//            globalReader?.initBook("\(fullBookPath.absoluteString)", "\(position)");
//            """
//        } else {
//            script = """
//            globalReader?.initBook("\(fullBookPath.absoluteString)");
//            """
//        }
//
//        webView.evaluateJavaScript(script) { success, error in
//            completionHandler?(success, error)
//            self.hasLoadedBook = true
//        }
//    }
//
//    func setTheme(completionHandler: ((Any?, Error?) -> Void)? = nil) {
//        let script = """
//        var _style = {
//            lineHeight: \(theme.lineHeight),
//            justify: \(theme.justify),
//            hyphenate: \(theme.hyphenate),
//            theme: {bg: "\(theme.bg.rawValue)", fg: "\(theme.fg.rawValue)"},
//            fontSize: \(theme.fontSize),
//        }
//
//        var _layout = {
//           gap: \(theme.gap),
//           maxInlineSize: \(theme.maxInlineSize),
//           maxBlockSize: \(theme.maxBlockSize),
//           maxColumnCount: \(theme.maxColumnCount),
//           flow: \(theme.flow),
//        }
//
//        globalReader?.setTheme({style: _style, layout: _layout})
//        """
//
//        theme.save()
//        webView.evaluateJavaScript(script, completionHandler: completionHandler)
//    }
// }
