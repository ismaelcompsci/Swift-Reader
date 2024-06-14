//
//  File.swift
//
//
//  Created by Mirna Olvera on 6/9/24.
//

import Foundation
import WebKit

public class HeadlessWebview: NSObject {
    public var webView: WKWebView
    private var htmlLocation: URL

    override init() {
        webView = WKWebView()
        webView.isInspectable = true
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        htmlLocation = URL.documentsDirectory.appendingPathComponent("index.html")

        if let extractorBundleJS = Bundle.module.url(forResource: "scripts/index", withExtension: "html") {
            try? FileManager.default.copyItem(at: extractorBundleJS, to: htmlLocation)
        }
    }

    public func loadMetadataExtractorJS() -> WKNavigation? {
        return webView.loadFileURL(htmlLocation, allowingReadAccessTo: URL.documentsDirectory)
    }
}

extension HeadlessWebview: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("DID FINISH LOADING")
    }
}
