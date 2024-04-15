//
//  PartialSourceBook.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc public protocol PartialSourceBookJSExport: JSExport {
    var id: String { get set }
    var title: String { get set }
    var image: String? { get set }
    var author: String? { get set }

    // swiftlint:disable:next identifier_name
    static func _create(id: String, title: String, image: String?, author: String?) -> PartialSourceBook
}

@objc public class PartialSourceBook: NSObject, PartialSourceBookJSExport, Identifiable {
    public var id: String
    public var title: String
    public var image: String?
    public var author: String?

    public init(id: String, title: String, image: String? = nil, author: String? = nil) {
        self.id = id
        self.title = title
        self.image = image
        self.author = author
    }

    // swiftlint:disable:next identifier_name
    public static func _create(id: String, title: String, image: String?, author: String?) -> PartialSourceBook {
        PartialSourceBook(id: id, title: title, image: image, author: author)
    }
}
