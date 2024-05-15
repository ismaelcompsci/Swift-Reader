//

//  SDBook.swift

//  Read

//

//  Created by Mirna Olvera on 5/7/24.

//

import Foundation
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

    var tags = [SDTag]()
    @Relationship(inverse: \SDCollection.books) var collections = [SDCollection]()
    @Relationship(
        deleteRule: .cascade,
        inverse: \SDHighlight.book
    ) var highlights = [SDHighlight]()

    @Relationship(
        deleteRule: .cascade,
        inverse: \SDReadingPosition.book
    ) var position: SDReadingPosition?

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
        addedAt: Foundation.Date = Date.now,
        updatedAt: Foundation.Date = Date.now,
        lastEngaged: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.summary = summary
        self.bookPath = bookPath
        self.coverPath = coverPath
        self.dateFinished = dateFinished
        self.addedAt = addedAt
        self.updatedAt = updatedAt
        self.lastEngaged = lastEngaged
    }
}

@Model
class SDTag {
    @Attribute(.unique) var id: UUID
    var name: String

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

    var books: [SDBook]

    init(createdAt: Date, name: String, books: [SDBook]) {
        self.id = .init()
        self.createdAt = createdAt
        self.name = name
        self.books = books
    }
}

@Model
class SDHighlight {
    @Attribute(.unique) var id: UUID

    var cfi: String?
    var ranges: String?
    var chapter: Int?
    var chapterTitle: String?
    var backgroundColor = "#FFFF00"
    var highlightText: String?
    var addedAt = Date.now
    var updatedAt = Date.now
    var highlightId: String?

    var book: SDBook?

    init(
        id: UUID,
        cfi: String? = nil,
        ranges: String? = nil,
        chapter: Int? = nil,
        chapterTitle: String? = nil,
        backgroundColor: String = "#FFFF00",
        highlightText: String? = nil,
        addedAt: Foundation.Date = Date.now,
        updatedAt: Foundation.Date = Date.now,
        highlightId: String? = nil
    ) {
        self.id = id
        self.cfi = cfi
        self.ranges = ranges
        self.chapter = chapter
        self.chapterTitle = chapterTitle
        self.backgroundColor = backgroundColor
        self.highlightText = highlightText
        self.addedAt = addedAt
        self.updatedAt = updatedAt
        self.highlightId = highlightId
    }
}

@Model
class SDReadingPosition {
    var chapterProgress: Double?
    var chapter: Int
    var updatedAt: Date
    var epubCfi: String?
    var progress: Double?

    var book: SDBook?

    init(
        chapterProgress: Double? = nil,
        chapter: Int,
        updatedAt: Date,
        epubCfi: String? = nil,
        progress: Double? = nil
    ) {
        self.chapterProgress = chapterProgress
        self.chapter = chapter
        self.updatedAt = updatedAt
        self.epubCfi = epubCfi
        self.progress = progress
    }
}
