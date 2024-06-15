//
//  File.swift
//
//
//  Created by Mirna Olvera on 6/9/24.
//

import Foundation
import WebKit

@MainActor
public class HeadlessWebview {
    public let webView: WKWebView
    private let htmlLocation: URL

    init() {
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
