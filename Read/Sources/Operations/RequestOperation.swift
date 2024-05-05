//
//  RequestOperation.swift
//  Read
//
//  Created by Mirna Olvera on 4/30/24.
//

import Foundation
import JavaScriptCore
import OSLog

class RequestOperation: AsyncResultOperation<Response, RequestOperation.Error> {
    public enum Error: Swift.Error {
        case canceled
        case internalClass
        case urlError
        case dataParsingFailed
        case httpResponseFailed
        case interceptFailed
        case underlying(error: Swift.Error)
    }

    private var dataTask: URLSessionTask?
    private let request: Request
    private let requestTimeout: Int
    private let interceptor: JSValue?

    init(request: Request, requestTimeout: Int, interceptor: JSValue?) {
        self.request = request
        self.requestTimeout = requestTimeout
        self.interceptor = interceptor
    }

    func intercept(completion: @escaping ((Result<Request, RequestOperation.Error>) -> Void)) {
        if let interceptor = interceptor,
           interceptor.hasProperty("interceptRequest"),
           let interceptRequest = interceptor.forProperty("interceptRequest"),
           interceptRequest.isUndefined == false
        {
            interceptRequest.call(withArguments: [request], completion: {
                result in
                switch result {
                case .success(let success):
                    if let success = success, let request = success.toObjectOf(Request.self) as? Request {
                        completion(.success(request))

                    } else {
                        completion(.failure(.interceptFailed))
                    }
                case .failure(let failure):
                    Logger.js.error("[\(type(of: self)):\(#function):\(#line)] Error - \(failure.localizedDescription)")
                    completion(.failure(.interceptFailed))
                }
            })
        } else {
            completion(.success(request))
        }
    }

    override public final func main() {
        // swiftformat:disable:next redundantSelf
        Logger.js.info("[\(type(of: self)):\(#function):\(#line)] RequestOperation - \(self.request.url)")

        intercept { [weak self] interceptResult in

            guard let self = self else { return }

            switch interceptResult {
            case .success(let request):

                guard let url = URL(string: request.url) else {
                    return self.finish(with: .failure(.urlError))
                }

                var urlRequest = URLRequest(url: url)
                urlRequest.timeoutInterval = TimeInterval(self.requestTimeout)
                urlRequest.httpMethod = request.method

                if let headers = request.headers {
                    urlRequest.allHTTPHeaderFields = headers
                }

                if let data = request.data, let data = data.data(using: .utf8) {
                    urlRequest.httpBody = data
                }

                self.dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in

                    do {
                        guard let self = self else {
                            throw RequestOperation.Error.internalClass
                        }
                        if let error = error {
                            throw RequestOperation.Error.underlying(error: error)
                        }

                        guard let data = data, let html = String(data: data, encoding: .utf8) else {
                            throw RequestOperation.Error.dataParsingFailed
                        }

                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw RequestOperation.Error.httpResponseFailed
                        }

                        let res = Response(
                            data: html,
                            status: httpResponse.statusCode,
                            headers: request.headers as? NSDictionary ?? [:],
                            request: request
                        )

                        self.finish(with: .success(res))
                    } catch {
                        if let error = error as? Error {
                            self?.finish(with: .failure(error))
                        }

                        self?.finish(with: .failure(.underlying(error: error)))
                    }
                }

                self.dataTask?.resume()
            case .failure(let failure):
                Logger.js.info("[\(type(of: self)):\(#function):\(#line)] RequestOperation - \(self.request.url): Error - \(failure)")
                self.finish(with: .failure(failure))
            }
        }
    }

    override public final func cancel() {
        dataTask?.cancel()
        cancel(with: .canceled)
    }
}
