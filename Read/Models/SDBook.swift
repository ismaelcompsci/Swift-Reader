//

//  SDBook.swift

//  Read

//

//  Created by Mirna Olvera on 5/7/24.

//

import Foundation
import SReader
import SwiftData

@Model
public class SDBook: Identifiable {
    @Attribute(.unique) public var id: UUID

    var title: String
    var author: String?
    var summary: String?
    var bookPath: String?
    var coverPath: String?
    var isFinsihed: Bool = false
    var dateFinished: Date?
    var addedAt = Date.now
    var updatedAt = Date.now
    var lastEngaged: Date?
    var lastOpened: Date?

    var position: SDPosition?

    var fullPath: URL? {
        if let path = bookPath {
            return URL.documentsDirectory.appending(path: path)
        } else {
            return nil
        }
    }

    var tags = [SDTag]()
    @Relationship(inverse: \SDCollection.books) var collections = [SDCollection]()
    @Relationship(deleteRule: .cascade, inverse: \SDHighlight.book) var highlights = [SDHighlight]()

    @Transient
    var titleNormalized: String {
        title.lowercased()
    }

    init(
        id: UUID,
        title: String,
        author: String? = nil,
        summary: String? = nil,
        bookPath: String? = nil,
        coverPath: String? = nil,
        dateFinished: Date? = nil,
        position: SDPosition? = nil,
        addedAt: Foundation.Date = Date.now,
        updatedAt: Foundation.Date = Date.now,
        lastOpened: Foundation.Date? = nil,
        lastEngaged: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.summary = summary
        self.bookPath = bookPath
        self.coverPath = coverPath
        self.dateFinished = dateFinished
        self.position = position
        self.addedAt = addedAt
        self.updatedAt = updatedAt
        self.lastOpened = lastOpened
        self.lastEngaged = lastEngaged
    }
}

@Model
class SDTag {
    @Attribute(.unique) var id: UUID
    var name: String

    init(name: String) {
        id = .init()

        self.name = name
    }
}

@Model
class SDCollection {
    @Attribute(.unique) var id: UUID

    var createdAt: Date
    var name: String

    var books: [SDBook]

    init(createdAt: Date, name: String, books: [SDBook]) {
        id = .init()
        self.createdAt = createdAt
        self.name = name
        self.books = books
    }
}

@Model
class SDHighlight {
    @Attribute(.unique) var id: String

    var locator: SRLocator
    var color: HighlightColor
    var created = Date()
    var progression: Double?

    var book: SDBook?

    init(
        id: String,
        locator: SRLocator,
        color: HighlightColor,
        created: Date = .now,
        progression: Double? = nil
    ) {
        self.id = id
        self.locator = locator
        self.color = color
        self.created = created
        self.progression = progression
        book = nil
    }

    init(_ highlight: SRHighlight) {
        id = highlight.id
        locator = highlight.locator
        color = highlight.color
        created = highlight.created
        progression = highlight.progression
    }

    func toSRHiglight() -> SRHighlight {
        SRHighlight(
            id: id,
            locator: locator,
            color: color,
            created: created
        )
    }
}

@Model
class SDPosition {
    var type: BookType
    var title: String?
    var text: String?

    var fragments: [String]
    var progression: Double?
    var totalProgression: Double?
    var position: Int?

    init(_ locater: SRLocator) {
        type = locater.type
        title = locater.title
        text = locater.text

        fragments = locater.locations.fragments
        progression = locater.locations.progression
        totalProgression = locater.locations.totalProgression
        position = locater.locations.position
    }

    func toSRLocater() -> SRLocator {
        SRLocator(
            type: type,
            title: title ?? "",
            locations: .init(
                fragments: fragments,
                progression: progression,
                totalProgression: totalProgression,
                position: position
            ),
            text: text
        )
    }
}
