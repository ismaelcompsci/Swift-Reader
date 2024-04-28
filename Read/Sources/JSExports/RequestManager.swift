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
    var interceptor: SourceInterceptor? { get set }

    func request(_ request: Request, _ options: JSValue) -> JSManagedValue
    static func createRequestManager(requestTimeout: Int, interceptor: SourceInterceptor?) -> RequestManager
}

@objc protocol SourceInterceptorJSExport: JSExport {
    var interceptRequest: JSValue { get set }
}

class SourceInterceptor: NSObject, SourceInterceptorJSExport {
    var interceptRequest: JSValue

    init(interceptRequest: JSValue) {
        self.interceptRequest = interceptRequest
    }
}

class RequestManager: NSObject, RequestManagerJSExport {
    var requestTimeout: Int
    var interceptor: SourceInterceptor?

//    var requests = [String: Request]()

    init(requestTimeout: Int, interceptor: SourceInterceptor? = nil) {
        self.requestTimeout = requestTimeout
        self.interceptor = interceptor
    }

    func request(_ request: Request, _ options: JSValue) -> JSManagedValue {
        let promise = JSValue(newPromiseIn: JSContext.current()) { [weak self] resolve, reject in
            guard let resolve = resolve, let reject = reject, let self = self else { return }

            Task {
                var finalRequest: Request = request

                if let interceptor = self.interceptor {
                    let interceptedRequest = try? await interceptor.interceptRequest.callAsync(withArguments: [request]).toObjectOf(Request.self) as? Request

                    finalRequest = interceptedRequest ?? request
                }

//                if let interceptor = self.interceptor {
//                    let previousIntercept = self.requests[request.url]
//
//                    if previousIntercept == nil, let interceptRequestJS = try? await interceptor.interceptRequest.callAsync(withArguments: [request]), let interceptedRequest = interceptRequestJS.toObjectOf(Request.self) as? Request {
//                        finalRequest = interceptedRequest
//                    } else {
//                        finalRequest = request
//                    }
//
//                } else {
//                    finalRequest = request
//                }
//
//                self.requests.updateValue(finalRequest, forKey: request.url)

                let url = URL(string: finalRequest.url)

                guard let url = url else {
                    reject.call(withArguments: [
                        [
                            "name": "URL Error",
                            "response": "Could not decode URL / Request."
                        ]
                    ])

                    return
                }

                var urlRequest = URLRequest(url: url)
                urlRequest.timeoutInterval = TimeInterval(self.requestTimeout)
                urlRequest.httpMethod = finalRequest.method

                do {
                    let (data, response) = try await URLSession.shared.data(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        Log("HTTPURLResponse was nil")
                        reject.call(withArguments: ["native response was nil"])
                        return
                    }

                    let res = Response(
                        data: String(data: data, encoding: .utf8),
                        status: httpResponse.statusCode,
                        headers: [:],
                        request: request
                    )

                    resolve.call(withArguments: [res])
                } catch {
                    reject.call(withArguments: [
                        [
                            "name": "FetchError",
                            "response": "\(error.localizedDescription)"
                        ]
                    ])
                    return
                }
            }
        }

        return JSManagedValue(value: promise)
    }

    class func createRequestManager(requestTimeout: Int, interceptor: SourceInterceptor?) -> RequestManager {
        return RequestManager(requestTimeout: requestTimeout, interceptor: interceptor)
    }
}
