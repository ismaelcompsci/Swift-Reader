//
//  HomeSection.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol HomeSectionJSExport: JSExport {
    var id: String { get }
    var title: String { get }
    var items: [PartialSourceBook] { get set }
    var containsMoreItems: Bool { get set }

    // swiftlint:disable:next identifier_name
    static func _create(id: String, title: String, items: [PartialSourceBook], containsMoreItems: Bool) -> HomeSection
}

@objc class HomeSection: NSObject, HomeSectionJSExport, Identifiable {
    var id: String
    var title: String
    var items: [PartialSourceBook]
    var containsMoreItems: Bool

    init(id: String, title: String, items: [PartialSourceBook], containsMoreItems: Bool) {
        self.id = id
        self.title = title
        self.items = items
        self.containsMoreItems = containsMoreItems
    }

    // swiftlint:disable:next identifier_name
    static func _create(id: String, title: String, items: [PartialSourceBook], containsMoreItems: Bool) -> HomeSection {
        return HomeSection(id: id, title: title, items: items, containsMoreItems: containsMoreItems)
    }
}
