//
//  SDBook+Extensions.swift
//  Read
//
//  Created by Mirna Olvera on 5/14/24.
//

import Foundation
import PDFKit
import SwiftReader

extension SDBook {
    func removeFromCollection(name: String) {
        let collection = collections.first(where: { $0.name == name })
        collection?.books.removeAll(where: { $0.id == self.id })
    }

    func addToCollection(name: String) {
        if let index = collections.firstIndex(where: { $0.name == name }) {
            let collection = collections[index]

            collection.books.append(self)
        } else {
            let collection = SDCollection(
                createdAt: .now,
                name: name,
                books: []
            )

            collections.append(collection)

            collection.books.append(self)
        }
    }

    func removePosition() {
        position = nil
    }

    func updatePosition(with relocate: Relocate) {
        if position == nil {
            position = SDReadingPosition(
                chapter: relocate.tocItem?.id ?? -1,
                updatedAt: relocate.updatedAt ?? .now,
                epubCfi: relocate.cfi,
                progress: relocate.fraction
            )

            position?.book = self
        } else {
            position?.progress = relocate.fraction
            position?.updatedAt = relocate.updatedAt ?? .now
            position?.epubCfi = relocate.cfi
        }
    }

    func updatePosition(page: PDFPage, document: PDFDocument) {
        let totalPages = CGFloat(document.pageCount)
        let currentPageIndex = CGFloat(document.index(for: page))

        if position == nil {
            position = SDReadingPosition(
                chapter: Int(currentPageIndex),
                updatedAt: .now,
                progress: currentPageIndex / totalPages
            )

            position?.book = self
        } else {
            position?.progress = currentPageIndex / totalPages
            position?.updatedAt = .now
            position?.chapter = Int(currentPageIndex)
        }
    }

    func addHighlight(_ pdfHighlight: PDFHighlight) {
        let positionData = try? JSONEncoder().encode(pdfHighlight.pos)

        var positionJSON: String?
        if let positionData = positionData {
            positionJSON = String(data: positionData, encoding: .utf8)
        }

        let new = SDHighlight(
            id: .init(),
            ranges: positionJSON,
            chapter: pdfHighlight.pos.first?.page,
            highlightText: pdfHighlight.content,
            highlightId: pdfHighlight.uuid.uuidString
        )

        highlights.append(new)

        new.book = self
    }

    func addHighlight(
        text: String,
        cfi: String,
        index: Int,
        label: String,
        addedAt: Date,
        updatedAt: Date
    ) {
        let highlight = SDHighlight(
            id: .init(),
            cfi: cfi,
            chapter: index,
            chapterTitle: label,
            highlightText: text
        )

        highlights.append(highlight)

        highlight.book = self
    }

    func removeHighlight(id: String) {
        highlights.removeAll(where: { $0.highlightId == id })
    }

    func removeHighlight(value: String) {
        highlights.removeAll(where: { $0.cfi == value })
    }
}
