//
//  HeadlessWebView.swift
//  Read
//
//  Created by Mirna Olvera on 1/30/24.
//

import Foundation
import os
import WebKit

class HeadlessWebView {
    static let shared = HeadlessWebView()

    let webView: WKWebView

    init() {
        print("HeadlessWebView init")
        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        self.webView = WKWebView()

        webView.isInspectable = true
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(LoggingMessageHandler(), name: "logHandler")

        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let newLocation = url.appendingPathComponent("index.html")

            do {
                try FileManager.default.removeItem(atPath: newLocation.absoluteString)
            } catch {
                print("Error removing file")
            }

            if let bundleHtml = Bundle.main.url(forResource: "Web.bundle/index", withExtension: "html") {
                do {
                    try FileManager.default.copyItem(at: bundleHtml, to: newLocation)
                } catch {
                    print("Error copying bundle: ")
                }

                webView.loadFileURL(newLocation, allowingReadAccessTo: URL.documentsDirectory)

            } else {
                // TODO: ERROR
                print("NO BUNDLE URL")
            }
        } else {
            // TODO: ERROR
            print("NO DOCUMENT URL")
        }
    }

    func greet() -> String {
        return "HELLO"
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
