//
//  SourceStateManager.swift
//  Read
//
//  Created by Mirna Olvera on 4/25/24.
//

import JavaScriptCore

@objc protocol StateManagerJSExport: JSExport {
    var keychain: SecureStateManager { get }

    func store(_ key: String, _ value: Any)
    func retrieve(_ key: String) -> Any?

    static func createSourceStateManager() -> SourceStateManager
}

class SourceStateManager: NSObject, StateManagerJSExport {
    var keychain: SecureStateManager = .init()

    var id: String?

    // TODO: Make retrieve and store async
    func store(_ key: String, _ value: Any) {
        var keyPrefix: String

        if let id = id {
            keyPrefix = id
        } else {
            let context = JSContext.current()
            keyPrefix = context?.name ?? "default"
        }

        SourceStatePersistanceManager.shared.write(keyPrefix + key, value)
    }

    func retrieve(_ key: String) -> Any? {
        var keyPrefix: String

        if let id = id {
            keyPrefix = id
        } else {
            let context = JSContext.current()
            keyPrefix = context?.name ?? "default"
        }

        return SourceStatePersistanceManager.shared.read(keyPrefix + key)
    }

    static func createSourceStateManager() -> SourceStateManager {
        return SourceStateManager()
    }
}

class SourceStatePersistanceManager {
    static let shared = SourceStatePersistanceManager()
    var userDefaults: UserDefaults

    init() {
        self.userDefaults = UserDefaults(suiteName: "SourcesStates") ?? UserDefaults.standard
    }

    func write(_ key: String, _ value: Any) {
        userDefaults.set(value, forKey: key)
    }

    func read(_ key: String) -> Any? {
        userDefaults.object(forKey: key)
    }
}
