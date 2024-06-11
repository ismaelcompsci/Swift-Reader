//
//  EBookReader+WebView.swift
//
//
//  Created by Mirna Olvera on 5/17/24.
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

public class EBookWebViewCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    var viewModel: EBookReaderViewModel

    init(viewModel: EBookReaderViewModel) {
        self.viewModel = viewModel
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let handlerCase = BookWebViewMessageHandlers(rawValue: message.name) {
            viewModel.handleMessage(from: handlerCase, with: message.body)
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewModel.finishedLoadingJavascript = true
    }
}

public struct EBookWebView: UIViewRepresentable {
    var viewModel: EBookReaderViewModel

    public init(viewModel: EBookReaderViewModel) {
        self.viewModel = viewModel
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = viewModel.webView

        webView.viewModel = viewModel

        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        let userContentController = webView.configuration.userContentController
        userContentController.removeAllScriptMessageHandlers()

        #if DEBUG
        webView.isInspectable = true
        let source = "function captureLog(msg) { window.webkit.messageHandlers.readerHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        userContentController.add(LoggingMessageHandler(), name: "readerHandler")
        #endif

        webView.addInteraction(viewModel.editingActions.editMenuInteraction)
        webView.addInteraction(viewModel.highlightActions.editMenuInteraction)

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

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    public func makeCoordinator() -> EBookWebViewCoordinator {
        return EBookWebViewCoordinator(viewModel: viewModel)
    }
}

class NoContextMenuWebView: WKWebView {
    var viewModel: EBookReaderViewModel?

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let viewModel = viewModel else { return false }

        return super.canPerformAction(action, withSender: sender)
            && viewModel.editingActions.canPerformAction(action)
    }

    override public func buildMenu(with builder: any UIMenuBuilder) {
        viewModel?.editingActions.buildMenu(with: builder)
    }
}

class LoggingMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logHandler" {
            print("LOG: \(message.body)")
        } else if message.name == "readerHandler" {
            print("READER LOG: \(message.body)")
        }
    }
}
