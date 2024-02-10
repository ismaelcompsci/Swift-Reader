//
//  BookRemover.swift
//  Read
//
//  Created by Mirna Olvera on 2/10/24.
//

import Foundation

enum BookRemover {
    static let documentsDir = URL.documentsDirectory

    static func removeBook(book: Book) {
        BookRemover.removeBookFile(book: book)
        BookRemover.removeBookCover(book: book)
    }

    static func removeBookFile(book: Book) {
        guard let bookPath = book.bookPath else {
            print("Book has no path")
            return
        }

        let fullBookPath = documentsDir.appending(path: bookPath)

        do {
            try FileManager.default.removeItem(at: fullBookPath)
        } catch {
            print("Failed to remove book \(error.localizedDescription)")
        }
    }

    static func removeBookCover(book: Book) {
        guard let coverPath = book.coverPath else {
            print("Book has no cover")
            return
        }

        let fullCoverPath = documentsDir.appending(path: coverPath)

        do {
            try FileManager.default.removeItem(at: fullCoverPath)
        } catch {
            print("Failed to remove book cover: \(error.localizedDescription)")
        }
    }
}
