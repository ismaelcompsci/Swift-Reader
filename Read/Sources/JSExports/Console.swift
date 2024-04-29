//
//  Console.swift
//  Read
//
//  Created by Mirna Olvera on 4/26/24.
//

import JavaScriptCore
import OSLog

@objc protocol ConsoleExports: JSExport {
    static func log(_ msg: String)
    static func info(_ msg: String)
    static func warn(_ msg: String)
    static func error(_ msg: String)
}

final class Console: NSObject, ConsoleExports {
    public class func log(_ msg: String) {
        Logger.js.log("\(msg)")
    }

    public class func info(_ msg: String) {
        Logger.js.info("\(msg)")
    }

    public class func warn(_ msg: String) {
        Logger.js.warning("\(msg)")
    }

    public class func error(_ msg: String) {
        Logger.js.error("\(msg)")
    }
}
