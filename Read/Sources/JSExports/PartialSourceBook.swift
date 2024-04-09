//
//  PartialSourceBook.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol PartialSourceBookJSExport: JSExport {
    var id: String { get set }
    var title: String { get set }
    var image: String? { get set }
    var author: String? { get set }

    // swiftlint:disable:next identifier_name
    static func _create(id: String, title: String, image: String?, author: String?) -> PartialSourceBook
}

@objc class PartialSourceBook: NSObject, PartialSourceBookJSExport, Identifiable {
    var id: String
    var title: String
    var image: String?
    var author: String?

    init(id: String, title: String, image: String? = nil, author: String? = nil) {
        self.id = id
        self.title = title
        self.image = image
        self.author = author
    }

    // swiftlint:disable:next identifier_name
    static func _create(id: String, title: String, image: String?, author: String?) -> PartialSourceBook {
        PartialSourceBook(id: id, title: title, image: image, author: author)
    }
}
