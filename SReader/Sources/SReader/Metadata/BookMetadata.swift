//
//  BookMetadata.swift
//  Read
//
//  Created by Mirna Olvera on 2/15/24.
//

import Foundation

public struct BookMetadata: Codable {
    public var title: String?
    public var author: [MetadataAuthor]?
    public var description: String?
    public var cover: String?
    public var subject: [String]?

    public var bookPath: String?
    public var bookCover: String?

    public enum CodingKeys: String, CodingKey {
        case title
        case author
        case description
        case cover
        case subject
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)

        if let authorArray = try? container.decodeIfPresent([String].self, forKey: .author) {
            // Case: authors is an array of strings
            self.author = authorArray.map { author in
                MetadataAuthor(name: author)
            }

        } else if let authorArray = try? container.decodeIfPresent([MetadataAuthor].self, forKey: .author) {
            // Case: authors is an array of dictionary with .name property
            self.author = authorArray.map { authorObject in
                MetadataAuthor(name: authorObject.name)
            }
        } else {
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

    public init(
        title: String? = nil,
        author: [MetadataAuthor]? = nil,
        description: String? = nil,
        cover: String? = nil,
        subject: [String]? = nil,
        bookPath: String? = nil,
        bookCover: String? = nil
    ) {
        self.title = title
        self.author = author
        self.description = description
        self.cover = cover
        self.subject = subject
        self.bookPath = bookPath
        self.bookCover = bookCover
    }
}

public struct MetadataAuthor: Codable {
    public var name: String?

    public init(name: String? = nil) {
        self.name = name
    }
}

public struct TagItem: Codable {
    public var name: String? = ""
}
