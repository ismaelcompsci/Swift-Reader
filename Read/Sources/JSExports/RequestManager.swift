//
//  RequestManager.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore
import OSLog

@objc protocol RequestManagerJSExport: JSExport {
    var requestTimeout: Int { get }
    var interceptor: SourceInterceptor? { get set }

    func request(_ request: Request) -> JSManagedValue
    static func createRequestManager(requestTimeout: Int, interceptor: SourceInterceptor?) -> RequestManager
}

@objc protocol SourceInterceptorJSExport: JSExport {
    var interceptRequest: JSManagedValue { get set }
}

class SourceInterceptor: NSObject, SourceInterceptorJSExport {
    var interceptRequest: JSManagedValue

    init(interceptRequest: JSManagedValue) {
        self.interceptRequest = interceptRequest
    }
}

class RequestManager: NSObject, RequestManagerJSExport {
    var requestTimeout: Int
    var interceptor: SourceInterceptor?

    let queue: OperationQueue = {
        let _queue = OperationQueue()
        _queue.name = "com.sr.RequestManager.OperationQueue"
        _queue.maxConcurrentOperationCount = 3

        return _queue
    }()

    init(requestTimeout: Int, interceptor: SourceInterceptor? = nil) {
        self.requestTimeout = requestTimeout
        self.interceptor = interceptor
    }

    func request(_ request: Request) -> JSManagedValue {
        let promise = JSValue(newPromiseIn: JSContext.current()) { [weak self] resolve, reject in
            let requestOperation = RequestOperation(request: request, requestTimeout: self?.requestTimeout ?? 20_000)

            requestOperation.onResult = { result in
                switch result {
                case .success(let response):
                    resolve?.call(withArguments: [response])

                case .failure(let error):
                    reject?.call(withArguments: [
                        [
                            "name": error,
                            "response": error.localizedDescription
                        ]
                    ])
                }
            }

            self?.queue.addOperations([requestOperation], waitUntilFinished: false)
        }

        return JSManagedValue(value: promise)
    }

    static func createRequestManager(requestTimeout: Int, interceptor: SourceInterceptor?) -> RequestManager {
        return RequestManager(requestTimeout: requestTimeout, interceptor: interceptor)
    }
}
