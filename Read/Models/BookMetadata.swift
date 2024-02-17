//
//  BookMetadata.swift
//  Read
//
//  Created by Mirna Olvera on 2/15/24.
//

import Foundation

struct BookMetadata: Codable {
    var title: String? = ""
    var author: [Author]? = []
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
            // Case: authors is an array of strings
            self.author = authorArray.map { author in
                Author(name: author)
            }

        } else if let authorArray = try? container.decodeIfPresent([Author].self, forKey: .author) {
            // Case: authors is an array of dictionary with .name property
            self.author = authorArray.map { authorObject in
                Author(name: authorObject.name)
            }
        } else {
            // Case: unknown format for authors, handle as needed
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
