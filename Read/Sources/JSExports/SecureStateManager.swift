//
//  SecureStateManager.swift
//  Read
//
//  Created by Mirna Olvera on 5/2/24.
//

import Foundation
import JavaScriptCore
import KeychainSwift
import OSLog

// TODO: MAKE ASYNC
@objc protocol SecureStateManagerJSExport: JSExport {
    func store(_ key: String, _ value: Any)
    func retrieve(_ key: String) -> Any?

    static func createSourceStateManager() -> SecureStateManager
}

class SecureStateManager: NSObject, SecureStateManagerJSExport {
    func store(_ key: String, _ value: Any) {
        SecureStatePersistanceManager.shared.write(key, value)
    }

    func retrieve(_ key: String) -> Any? {
        SecureStatePersistanceManager.shared.read(key)
    }

    static func createSourceStateManager() -> SecureStateManager {
        return SecureStateManager()
    }
}

class SecureStatePersistanceManager {
    static let shared = SourceStatePersistanceManager()
    let keychain = KeychainSwift()

    func write(_ key: String, _ value: Any) {
        if let value = value as? String, let value = value.data(using: .utf8) {
            keychain.set(value, forKey: key, withAccess: .accessibleAfterFirstUnlock)
        }
        else if let value = value as? Int {
            keychain.set(String(value), forKey: key, withAccess: .accessibleAfterFirstUnlock)
        }
        else if let value = value as? Bool {
            keychain.set(value, forKey: key)
        }
        else if let value = value as? [String: Any] {
            let jsonData = try? JSONSerialization.data(withJSONObject: value)
            if let jsonData = jsonData {
                keychain.set(jsonData, forKey: key)
            }
        }
    }

    func read(_ key: String) -> Any? {
        return nil
    }
}
