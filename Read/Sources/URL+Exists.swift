//
//  URL+Exists.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation

extension URL {
    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
