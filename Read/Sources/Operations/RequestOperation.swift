//
//  RequestOperation.swift
//  Read
//
//  Created by Mirna Olvera on 4/30/24.
//

import Foundation
import OSLog

class RequestOperation: AsyncResultOperation<Response, RequestOperation.Error> {
    public enum Error: Swift.Error {
        case canceled
        case internalClass
        case urlError
        case dataParsingFailed
        case httpResponseFailed
        case underlying(error: Swift.Error)
    }

    private var dataTask: URLSessionTask?
    private let request: Request
    private let requestTimeout: Int

    init(request: Request, requestTimeout: Int) {
        self.request = request
        self.requestTimeout = requestTimeout
    }

    override public final func main() {
        // swiftformat:disable:next redundantSelf
        Logger.js.info("[\(type(of: self)):\(#function):\(#line)] RequestOperation - \(self.request.url)")
        guard let url = URL(string: request.url) else {
            return finish(with: .failure(.urlError))
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.timeoutInterval = TimeInterval(requestTimeout)
        urlRequest.httpMethod = request.method

        dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in

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
                    headers: [:],
                    request: self.request
                )

                self.finish(with: .success(res))
            } catch {
                if let error = error as? Error {
                    self?.finish(with: .failure(error))
                }

                self?.finish(with: .failure(.underlying(error: error)))
            }
        }

        dataTask?.resume()
    }

    override public final func cancel() {
        dataTask?.cancel()
        cancel(with: .canceled)
    }
}
