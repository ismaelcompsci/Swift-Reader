//

//  SDBook.swift

//  Read

//

//  Created by Mirna Olvera on 5/7/24.

//

import Foundation
import SReader
import SwiftData
import UIKit

@Model
public class SDBook: Identifiable {
    @Attribute(.unique) public var id: UUID

    var title: String
    var author: String?
    var summary: String?
    var bookPath: String?
    var coverPath: String?
    var isFinished: Bool = false
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

    var imagePath: URL? {
        guard let coverPath = coverPath else {
            return nil
        }

        let documentsPath = URL.documentsDirectory
        return documentsPath.appending(path: coverPath)
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
        lastEngaged: Date? = nil,
        isFinished: Bool = false
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
        self.isFinished = isFinished
    }
}

extension SDBook {
    func removeLocator() {
        position = nil
    }

    func update(_ locator: SRLocator) {
        position = SDPosition(locator)
    }

    func highlighted(_ highlight: SRHighlight) {
        let persistedHighlight = SDHighlight(highlight)
        highlights.append(persistedHighlight)
        persistedHighlight.book = self
    }

    func unhighlighted(_ highlight: SRHighlight) {
        highlights.removeAll(where: { $0.id == highlight.id })
    }
}
