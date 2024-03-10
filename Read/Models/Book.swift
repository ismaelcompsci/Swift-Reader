//
//  Book.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import Foundation
import RealmSwift

class Author: EmbeddedObject {
    @Persisted var name: String = ""
}

class Tag: EmbeddedObject {
    @Persisted var name: String = ""
}

class Book: Object, ObjectKeyIdentifiable, Identifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title = ""
    @Persisted var authors: List<Author> = List()
    @Persisted var summary: String?
    @Persisted var tags: List<Tag> = List()
    @Persisted var language: String?
    @Persisted var bookPath: String?
    @Persisted var coverPath: String?
    @Persisted var readingSeconds: Int = 0
    @Persisted var addedAt: Date = .now
    @Persisted var updatedAt: Date = .now

    @Persisted var processed: Bool = false

    @Persisted var readingPosition: ReadingPosition?
    @Persisted var highlights: List<BookHighlight> = List()
}

extension Book {
    static let example1 = Book(value: ["title": "The Witcher", "authors": [Author.exampleAuthor], "summary": "A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. ", "language": "en"])
    static let example2 = Book(value: ["title": "The Game of Thrones", "authors": [Author.exampleAuthor], "summary": "A guy with white hair killin g monsters and stuff. But again", "language": "en"])

    static let exampleArray = [Book.example1, Book.example2]
}

extension Author {
    static let exampleAuthor = Author(value: ["name": "Andrew Spacewalwoaski"])
}
