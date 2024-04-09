//
//  SourceBook.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol SourceBookJSExport: JSExport {
    var id: String { get set }
    var bookInfo: BookInfo { get set }

    // swiftlint:disable:next identifier_name
    static func _createSourceBook(id: String, bookInfo: BookInfo) -> SourceBook
}

class SourceBook: NSObject, SourceBookJSExport {
    var id: String
    var bookInfo: BookInfo

    init(id: String, bookInfo: BookInfo) {
        self.id = id
        self.bookInfo = bookInfo
    }

    // swiftlint:disable:next identifier_name
    class func _createSourceBook(id: String, bookInfo: BookInfo) -> SourceBook {
        SourceBook(id: id, bookInfo: bookInfo)
    }
}
