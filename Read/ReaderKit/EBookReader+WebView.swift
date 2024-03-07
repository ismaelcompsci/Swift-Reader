//
//  EBookReader+WebView.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI
import WebKit

enum BookWebViewMessageHandlers: String {
    case initiatedSwiftReader
    case tapHandler
    case selectedText
    case relocate
    case didTapHighlight
}

class EBookWebViewCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    var viewModel: EBookReaderViewModel

    init(viewModel: EBookReaderViewModel) {
        self.viewModel = viewModel
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let handlerCase = BookWebViewMessageHandlers(rawValue: message.name) {
            viewModel.messageFrom(fromHandler: handlerCase,
                                  message: message.body)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("HAS FINISSHED LOADING JS")
        viewModel.hasFinishedLoadingJS = true
    }
}

struct EBookWebView: UIViewRepresentable {
    var viewModel: EBookReaderViewModel

    init(viewModel: EBookReaderViewModel) {
        self.viewModel = viewModel
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.webView

        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator

        let userContentController = webView.configuration.userContentController

        userContentController.removeAllScriptMessageHandlers()

        let source = "function captureLog(msg) { window.webkit.messageHandlers.readerHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        userContentController.add(LoggingMessageHandler(), name: "readerHandler")

        userContentController.add(context.coordinator, name: BookWebViewMessageHandlers.initiatedSwiftReader.rawValue)

        userContentController.add(context.coordinator,
                                  name: BookWebViewMessageHandlers.tapHandler.rawValue)

        userContentController.add(context.coordinator,
                                  name: BookWebViewMessageHandlers.selectedText.rawValue)

        userContentController.add(context.coordinator,
                                  name: BookWebViewMessageHandlers.relocate.rawValue)

        userContentController.add(context.coordinator,
                                  name: BookWebViewMessageHandlers.didTapHighlight.rawValue)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> EBookWebViewCoordinator {
        return EBookWebViewCoordinator(viewModel: viewModel)
    }
}

class NoContextMenuWebView: WKWebView {
    static let shared = NoContextMenuWebView()

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
