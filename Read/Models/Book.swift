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
    @Persisted var author: List<AuthorBook> = List()
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
    static let example1 = Book(value: ["title": "The Witcher", "author": [AuthorBook.exampleAuthor], "summary": "A guy with white hair killin g monsters and stuff.", "language": "en"])
    static let example2 = Book(value: ["title": "The Game of Thrones", "author": [AuthorBook.exampleAuthor], "summary": "A guy with white hair killin g monsters and stuff. But again", "language": "en"])

    static let exampleArray = [Book.example1, Book.example2]
}

extension AuthorBook {
    static let exampleAuthor = AuthorBook(value: ["name": "Andrew Spacewalwoaski"])
}

/**

 subject?:
     | string
     | string[]
     | { name: string; sortAs: string; code: string; scheme: string };

 */

struct BookMetadata: Codable {
    var title: String? = ""
    var author: [Author]?
    var description: String? = ""
    var cover: String? = ""
    var subject: [String]? = []

    var bookPath: String?
    var bookCover: String?

    enum CodingKeys: String, CodingKey {
        case title
        case author
        case description
        case cover
        case subject
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)

        if let authorArray = try? container.decodeIfPresent([String].self, forKey: .author) {
            // Case: author is an array of strings
            self.author = authorArray.map { author in
                Author(name: author)
            }

        } else if let authorArray = try? container.decodeIfPresent([Author].self, forKey: .author) {
            // Case: author is an array of dictionary with .name property
            self.author = authorArray.map { authorObject in
                Author(name: authorObject.name)
            }
        } else {
            // Case: unknown format for author, handle as needed
            self.author = nil
        }

        if let tagString = try? container.decodeIfPresent(String.self, forKey: .subject) {
            self.subject = [tagString]
        } else if let tagArray = try? container.decodeIfPresent([String].self, forKey: .subject) {
            self.subject = tagArray
        } else if let tagObjectArray = try? container.decodeIfPresent([TagItem].self, forKey: .subject) {
            self.subject = tagObjectArray.map { object in
                object.name ?? ""
            }
        } else {
            self.subject = nil
        }

        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.cover = try container.decodeIfPresent(String.self, forKey: .cover)
    }
}

struct Author: Codable {
    var name: String? = ""
}

struct TagItem: Codable {
    var name: String? = ""
}
