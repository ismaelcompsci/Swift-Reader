//
//  JSError.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

/**
 github.com/ionic-team/capacitor-background-runner/blob/main/packages/ios-engine/Sources/RunnerEngine/JSError.swift#L16
 */
@objc protocol JSErrorExports: JSExport {
    var cause: Any? { get set }
    var message: String { get set }

    func toString() -> String
}

@objc public class JSError: NSObject, JSErrorExports {
    dynamic var cause: Any?
    dynamic var message: String

    override public init() {
        message = ""
        cause = nil
    }

    public init(message: String) {
        self.message = message
        cause = nil
    }

    func toString() -> String {
        return message
    }
}
