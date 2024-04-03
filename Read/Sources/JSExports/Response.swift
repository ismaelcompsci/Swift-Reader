//
//  Response.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol ResponseJSExport: JSExport {
    var data: String? { get }
    var status: Int { get }
    var headers: NSDictionary { get }
    var request: Request { get }
    // swiftlint:disable:next identifier_name
    static func _createResponse(data: String?, status: Int, headers: NSDictionary, request: Request) -> Response
}

class Response: NSObject, ResponseJSExport {
    var data: String?
    var status: Int
    var headers: NSDictionary
    var request: Request

    init(data: String? = nil, status: Int, headers: NSDictionary, request: Request) {
        self.data = data
        self.status = status
        self.headers = headers
        self.request = request
    }

    // swiftlint:disable:next identifier_name
    class func _createResponse(data: String?, status: Int, headers: NSDictionary, request: Request) -> Response {
        Response(data: data, status: status, headers: headers, request: request)
    }
}
