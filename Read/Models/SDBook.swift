//

//  SDBook.swift

//  Read

//

//  Created by Mirna Olvera on 5/7/24.

//

import Foundation

import SwiftData

@Model

class SDBook: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var tags = [Tag]()
    var collections = [SDCollection]()

    init(title: String) {
        self.id = .init()

        self.title = title
    }
}

@Model

class SDTag {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(inverse: \SDBook.tags) var books = [Book]()

    init(name: String) {
        self.id = .init()

        self.name = name
    }
}

@Model
class SDCollection {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var name: String

    @Relationship(inverse: \SDBook.collections) var books = [SDBook]()

    init(createdAt: Date, name: String) {
        self.id = .init()

        self.createdAt = createdAt

        self.name = name
    }
}
