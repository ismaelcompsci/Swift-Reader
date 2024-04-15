//
//  RequestManager.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol RequestManagerJSExport: JSExport {
    var requestTimeout: Int { get }

    var request: @convention(block) (Request, JSValue) -> JSValue { get }
    static func createRequestManager(requestTimeout: Int) -> RequestManager
}

class RequestManager: NSObject, RequestManagerJSExport {
    var requestTimeout: Int

    init(requestTimeout: Int) {
        self.requestTimeout = requestTimeout
    }

    class func create() -> RequestManager {
        RequestManager(requestTimeout: 20_000)
    }

    var request: @convention(block) (Request, JSValue) -> JSValue = { request, _ in
        let session = URLSession.shared

        let url = URL(string: request.url)

        guard let url = url else {
            return JSValue(newErrorFromMessage: "invalid url", in: JSContext.current())
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = request.method

        return JSValue(newPromiseIn: JSContext.current()) { resolve, reject in
            let task = session.dataTask(with: urlRequest) { data, response, err in
                if let err = err {
                    Log("fetch failed: \(err.localizedDescription)")
                    let jsErr = JSError(message: err.localizedDescription)
                    reject?.call(withArguments: [jsErr as Any])
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    Log("HTTPURLResponse was nil")
                    let jsErr = JSError(message: "native response was nil")
                    reject?.call(withArguments: [jsErr as Any])
                    return
                }

                let res = Response(
                    data: data != nil ? String(data: data!, encoding: .utf8) : nil,
                    status: httpResponse.statusCode,
                    headers: [:],
                    request: request
                )

                resolve?.call(withArguments: [res])
            }

            task.resume()
        }
    }

    // swiftlint:disable:next identifier_name
//    class func _request(_ request: Request) -> JSValue {}

    class func createRequestManager(requestTimeout: Int) -> RequestManager {
        RequestManager(requestTimeout: requestTimeout)
    }
}
