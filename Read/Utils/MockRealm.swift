//
//  MockRealm.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import Foundation
import RealmSwift

class MockRealms {
    static var config: Realm.Configuration {
        MockRealms.previewRealm.configuration
    }

    static var previewRealm: Realm = {
        var realm: Realm
        let identifier = "previewRealm"
        let config = Realm.Configuration(inMemoryIdentifier: identifier)
        do {
            realm = try Realm(configuration: config)
            try realm.write {
//                for index in 0 ... 5 {
                realm.add(Book.example1)
//                }
            }
            return realm
        } catch {
            fatalError("Error: \(error.localizedDescription)")
        }
    }()

    init() {}
}
