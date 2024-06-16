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

    public init(createdAt: Date, name: String, books: [SDBook], icon: String = "text.justify.left") {
        id = .init()
        self.createdAt = createdAt
        self.name = name
        self.books = books
        self.icon = icon
    }
}
