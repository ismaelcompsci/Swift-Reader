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
    var data: String? { get set }
    var headers: [String: String]? { get set }

    // swiftlint:disable:next identifier_name
    static func _createRequest(url: String, method: String, data: String?, headers: [String: String]?) -> Request
}

class Request: NSObject, RequestJSExport {
    dynamic var url: String
    dynamic var method: String
    dynamic var data: String?
    dynamic var headers: [String: String]?

    init(url: String, method: String, data: String?, headers: [String: String]?) {
        self.url = url
        self.method = method
        self.headers = headers
        self.data = data
    }

    // swiftlint:disable:next identifier_name
    class func _createRequest(url: String, method: String, data: String?, headers: [String: String]?) -> Request {
        Request(url: url, method: method, data: data, headers: headers)
    }
}
