//
//  Log.swift
//  Read
//
//  Created by Mirna Olvera on 4/29/24.
//

import Foundation
import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let general = Logger(subsystem: subsystem, category: "General")
    static let js = Logger(subsystem: subsystem, category: "Javascript")
}

class SRLogger {
    static let general = Logger.general
    static let js = Logger.general

    init() {}
}
