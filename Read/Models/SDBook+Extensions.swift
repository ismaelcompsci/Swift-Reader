//
//  SDBook+Extensions.swift
//  Read
//
//  Created by Mirna Olvera on 5/14/24.
//

import Foundation
import PDFKit
import SReader

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

    func removeLocator() {
        position = nil
    }

    func update(_ locator: SRLocator) {
        self.position = SDPosition(locator)
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
