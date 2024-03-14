//
//  BookHighlight.swift
//  Read
//
//  Created by Mirna Olvera on 2/19/24.
//

import Foundation
import RealmSwift

class BookHighlight: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId

    @Persisted var cfi: String? = nil // non-pdf
    @Persisted var ranges: String? // pdf

    @Persisted var chapter: Int?
    @Persisted var chapterTitle: String?

    @Persisted var backgroundColor: String = "#FFFF00"

    @Persisted var highlightText: String? = nil

    @Persisted var addedAt: Date = .now
    @Persisted var updatedAt: Date = .now

    @Persisted var highlightId: String?

    // Backlink to the book. This is automatically updated whenever
    // this highlight is added to or removed from a book's highlights list.
    @Persisted(originProperty: "highlights") var assignee: LinkingObjects<Book>

    override init() {}

    init?(pdfHighlight: PDFHighlight) {
        guard let posData = try? JSONEncoder().encode(pdfHighlight.pos),
              let pos = String(data: posData, encoding: .utf8)
        else { return nil }

//        self.chapterTitle = pdfHighlight.pos.first?.page
        self.highlightId = pdfHighlight.uuid.uuidString
        self.highlightText = pdfHighlight.content
        self.chapter = pdfHighlight.pos.first?.page
        self.ranges = pos
        self.addedAt = .now
        self.updatedAt = .now

        self.cfi = nil
    }
}

extension BookHighlight {
    func toPDFHighlight() -> PDFHighlight? {
        guard let highlightId, let uuid = UUID(uuidString: highlightId),
              let posData = ranges?.data(using: .utf8),
              let pos = try? JSONDecoder().decode([PDFHighlight.PageLocation].self, from: posData)
        else {
            return nil
        }

        return PDFHighlight(uuid: uuid, pos: pos, content: highlightText)
    }
}
