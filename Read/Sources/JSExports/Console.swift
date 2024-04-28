//
//  Console.swift
//  Read
//
//  Created by Mirna Olvera on 4/26/24.
//

import JavaScriptCore

@objc protocol ConsoleExports: JSExport {
    static func log(_ msg: String)
    static func info(_ msg: String)
    static func warn(_ msg: String)
    static func error(_ msg: String)
}

final class Console: NSObject, ConsoleExports {
    public class func log(_ msg: String) {
        Log("\(msg)")
    }

    public class func info(_ msg: String) {
        Log("\(msg)")
    }

    public class func warn(_ msg: String) {
        Log("\(msg)")
    }

    public class func error(_ msg: String) {
        Log("\(msg)")
    }
}
