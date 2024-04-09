//
//  SearchRequest.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol SearchRequestJSExport: JSExport {
    var title: String? { get }
    var parameters: NSDictionary { get }
}

@objc class SearchRequest: NSObject, SearchRequestJSExport {
    var title: String?
    var parameters: NSDictionary

    init(title: String? = nil, parameters: NSDictionary) {
        self.title = title
        self.parameters = parameters
    }
}
