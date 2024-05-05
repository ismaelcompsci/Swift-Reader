//
//  JSValue.swift
//  Read
//
//  Created by Mirna Olvera on 4/27/24.
//

import Foundation
import JavaScriptCore

public extension JSValue {
    var hasValue: Bool {
        return !isUndefined && !isNull
    }

    func call(withArguments args: [Any] = [], completion: @escaping (Result<JSValue?, Error>) -> Void) {
        let onFulfilled: @convention(block) (JSValue) -> Void = { value in
            completion(.success(value))
        }
        let onRejected: @convention(block) (JSValue) -> Void = { error in
            let error = JSContext.getErrorFrom(key: "JS async function", error: error)
            completion(.failure(error))
        }

        let promiseArgs = [
            unsafeBitCast(onFulfilled, to: JSValue.self),
            unsafeBitCast(onRejected, to: JSValue.self)
        ]

        let promise = call(withArguments: args)
        promise?.invokeMethod("then", withArguments: promiseArgs)
    }

    /// - Parameters:
    ///   - withArguments: Optional arguments
    /// - Returns: The return value of the function
    func callAsync(withArguments: [Any] = []) async throws -> JSValue {
        try await withCheckedThrowingContinuation { continuation in
            let onFulfilled: @convention(block) (JSValue) -> Void = {
                continuation.resume(returning: $0)
            }
            let onRejected: @convention(block) (JSValue) -> Void = { error in
                let error = JSContext.getErrorFrom(key: "JS async function", error: error)
                continuation.resume(throwing: error)
            }

            let promiseArgs = [
                unsafeBitCast(onFulfilled, to: JSValue.self),
                unsafeBitCast(onRejected, to: JSValue.self)
            ]

            let promise = call(withArguments: withArguments)
            promise?.invokeMethod("then", withArguments: promiseArgs)
        }
    }

    func invokeAsyncMethod<T: JSExport>(methodKey: String, args: [Any] = []) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let onFulfilled: @convention(block) (JSExport) -> Void = {
                if let genericValue = $0 as? T {
                    continuation.resume(returning: genericValue)
                } else {
                    continuation.resume(throwing: ExtensionError.invalid)
                }
            }

            let onRejected: @convention(block) (JSValue) -> Void = { error in
                let error = JSContext.getErrorFrom(key: methodKey, error: error)
                continuation.resume(throwing: error)
            }

            let promiseArgs = [
                unsafeBitCast(onFulfilled, to: JSValue.self),
                unsafeBitCast(onRejected, to: JSValue.self)
            ]

            guard let promise = self.invokeMethod(methodKey, withArguments: args), promise.hasValue else {
                let error = NSError(
                    domain: methodKey,
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Javascript executaion failed or returned an unexpected value."]
                )
                continuation.resume(throwing: error)
                return
            }

            promise.invokeMethod("then", withArguments: promiseArgs)
        }
    }
}

extension JSContext {
    static func getErrorFrom(key: String, error: JSValue) -> NSError {
        var userInfo: [String: Any] = [:]

        if error.isObject {
            userInfo = error.toDictionary() as? [String: Any] ?? [:]
        } else {
            userInfo[NSLocalizedDescriptionKey] = error.toString() ?? "UnknownError"
        }

        return NSError(domain: key, code: 0, userInfo: userInfo)
    }
}
