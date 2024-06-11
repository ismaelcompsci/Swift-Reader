////
////  Reader.swift
////  Read
////
////  Created by Mirna Olvera on 4/12/24.
////

import OSLog
import SwiftUI

struct Reader: View {
    var isPdf: Bool
    var url: URL
    var book: SDBook

    init(book: SDBook) {
        let bookPathURL = URL.documentsDirectory.appending(path: book.bookPath ?? "")
        self.url = bookPathURL
        self.isPdf = bookPathURL.lastPathComponent.hasSuffix(".pdf")
        self.book = book
    }

    var body: some View {
        Group {
            if isPdf {
                PDFReader(book: book)
            } else {
                EBookReader(book: book)
            }
        }
        .task {
            do {
                try await Task.sleep(nanoseconds: 7_500_000_000)
                book.lastEngaged = .now
            } catch {
                Logger.general.debug("Did not update last engaged for book: \(book.id)")
            }
        }
    }
}
