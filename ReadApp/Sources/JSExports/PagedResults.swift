//
//  PagedResults.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol PagedResultsJSExport: JSExport {
    var results: [PartialSourceBook] { get set }
    var metadata: Any? { get set }
}

@objc class PagedResults: NSObject, PagedResultsJSExport {
    var results: [PartialSourceBook]
    var metadata: Any?

    init(results: [PartialSourceBook], metadata: Any? = nil) {
        self.results = results
        self.metadata = metadata
    }
}
