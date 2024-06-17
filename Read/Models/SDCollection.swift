//
//  SDCollection.swift
//  Read
//
//  Created by Mirna Olvera on 6/16/24.
//

import Foundation
import SwiftData

@Model
public class SDCollection: Identifiable {
    @Attribute(.unique) public var id: UUID

    public var createdAt: Date
    public var name: String
    public var books: [SDBook]
    public var icon: String

    public var editable: Bool
    public var addable: Bool
    public var removable: Bool

    public init(
        createdAt: Date = .now,
        name: String,
        books: [SDBook],
        icon: String = "text.justify.left",
        editable: Bool = true,
        addable: Bool = true,
        removable: Bool = true
    ) {
        id = .init()
        self.createdAt = createdAt
        self.name = name
        self.books = books
        self.icon = icon
        self.addable = addable
        self.editable = editable
        self.removable = removable
    }
}
