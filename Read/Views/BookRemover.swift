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
        BookRemover.removeBookDirectory(book: book)
    }

    static func removeBookDirectory(book: Book) {
        guard let bookPath = book.bookPath else {
            print("Book has no path")
            return
        }

        let fullBookPath = documentsDir.appending(path: bookPath)
        let directoryPath = fullBookPath.deletingLastPathComponent()

        do {
            try FileManager.default.removeItem(at: directoryPath)
        } catch {
            print("Failed to remove book \(error.localizedDescription)")
        }
    }
}
