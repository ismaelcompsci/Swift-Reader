//
//  Book.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import Foundation
import RealmSwift

class ReadingPosition: EmbeddedObject {
    @Persisted var chapterProgress: Double?
    @Persisted var chapter: Int
    @Persisted var updatedAt: Date
    @Persisted var epubCfi: String?
    @Persisted var progress: Double?
}

class AuthorBook: EmbeddedObject {
    @Persisted var name: String = ""
}

class Tag: EmbeddedObject {
    @Persisted var name: String = ""
}

class Book: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title = ""
    @Persisted var authors: List<AuthorBook> = List()
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
}

extension Book {
    static let example1 = Book(value: ["title": "The Witcher", "authors": [AuthorBook.exampleAuthor], "summary": "A guy with white hair killin g monsters and stuff.", "language": "en"])
    static let example2 = Book(value: ["title": "The Game of Thrones", "authors": [AuthorBook.exampleAuthor], "summary": "A guy with white hair killin g monsters and stuff. But again", "language": "en"])

    static let exampleArray = [Book.example1, Book.example2]
}

extension AuthorBook {
    static let exampleAuthor = AuthorBook(value: ["name": "Andrew Spacewalwoaski"])
}
