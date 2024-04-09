//
//  Request.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol RequestJSExport: JSExport {
    var url: String { get set }
    var method: String { get set }

    // swiftlint:disable:next identifier_name
    static func _createRequest(url: String, method: String) -> Request
}

class Request: NSObject, RequestJSExport {
    dynamic var url: String
    dynamic var method: String

    init(url: String, method: String) {
        self.url = url
        self.method = method
    }

    // swiftlint:disable:next identifier_name
    class func _createRequest(url: String, method: String) -> Request {
        Request(url: url, method: method)
    }
}
