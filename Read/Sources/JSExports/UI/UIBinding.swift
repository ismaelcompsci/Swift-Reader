//
//  UIBinding.swift
//  Read
//
//  Created by Mirna Olvera on 5/2/24.
//

import Foundation
import JavaScriptCore
import SwiftUI

class UIBinding: NSObject {
    var id: String

    var _get: JSValue
    var _set: JSValue?

    init(id: String, _get: JSValue, _set: JSValue) {
        self.id = id
        self._get = _get
        self._set = _set
    }

    func get() {}
    func set(newValue: Any) {}
}
