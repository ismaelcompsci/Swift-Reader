//
//  ReaderWebView.swift
//  Read
//
//  Created by Mirna Olvera on 2/5/24.
//

import Foundation
import SwiftUI
import WebKit

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

enum WebKitMessageHandlers: String {
    case bookRendered
    case tapHandler
    case selectedText
    case relocate
    case didTapHighlight
}

extension ReaderWebViewCoordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let handlerCase = WebKitMessageHandlers(rawValue: message.name) {
            viewModel.messageFrom(fromHandler: handlerCase,
                                  message: message.body)
        }
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
            print("[ReaderWebView] makeUIView: no web view")

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

        userContentController.add(context.coordinator,
                                  name: WebKitMessageHandlers.didTapHighlight.rawValue)

        // TODO: Remove
        webView.isInspectable = true /* DEBUG ONLY */

        return webView
    }

    func updateUIView(_ uiView: CustomWebView, context: Context) {}

    func makeCoordinator() -> ReaderWebViewCoordinator {
        return ReaderWebViewCoordinator(viewModel: vm)
    }
}
