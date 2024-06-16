//
//  ContextMenuModifier.swift
//  Read
//
//  Created by Mirna Olvera on 6/13/24.
//

import SwiftUI

struct ContextMenuModifier: ViewModifier {
    var navigator: Navigator
    let book: SDBook

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if book.isFinsihed == true {
                    Button("Mark as Still Reading", systemImage: "minus.circle") {
                        book.isFinsihed = false
                        book.dateFinished = nil

                        try? BookManager.shared.removeFromCollection(book: book, name: "Finished")
                    }
                } else {
                    Button("Mark as Finished", systemImage: "checkmark.circle") {
                        book.isFinsihed = true
                        book.dateFinished = .now

                        try? BookManager.shared.addToCollection(book: book, name: "Finished")
                    }
                }

                if book.collections.contains(where: { $0.name == "Want To Read" }) {
                    Button("Remove from Want to Read", systemImage: "minus.circle") {
                        try? BookManager.shared.removeFromCollection(book: book, name: "Want To Read")
                    }
                } else {
                    Button("Add To Want to Read", systemImage: "text.badge.star") {
                        try? BookManager.shared.addToCollection(book: book, name: "Want To Read")
                    }
                }

                Button("Share", systemImage: "square.and.arrow.up.fill") {
                    showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                }

                Button("Edit", systemImage: "pencil") {
                    navigator.presentedSheet = .editBookDetails(book: book)
                }

                if book.position != nil {
                    Button("Clear progress", systemImage: "clear.fill") {
                        book.removeLocator()
                    }
                }

                Button("Delete", systemImage: "trash.fill", role: .destructive) {
                    BookManager.shared.delete(book)
                }
            }
    }
}
