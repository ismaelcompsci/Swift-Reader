//
//  SearchRequest.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc public protocol SearchRequestJSExport: JSExport {
    var title: String? { get }
    var parameters: NSDictionary { get }
}

@objc public class SearchRequest: NSObject, SearchRequestJSExport {
    public var title: String?
    public var parameters: NSDictionary

    public init(title: String? = nil, parameters: NSDictionary) {
        self.title = title
        self.parameters = parameters
    }
}
