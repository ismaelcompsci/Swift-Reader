//
//  Reader.swift
//  Read
//
//  Created by Mirna Olvera on 4/12/24.
//

import SwiftUI

struct Reader: View {
    var isPdf: Bool
    var url: URL
    var book: Book

    init(book: Book) {
        let bookPathURL = URL.documentsDirectory.appending(path: book.bookPath ?? "")
        self.url = bookPathURL
        self.isPdf = bookPathURL.lastPathComponent.hasSuffix(".pdf")
        self.book = book
    }

    var body: some View {
        if isPdf {
            PDF(url: url, book: book)
        } else {
            EBookView(url: url, book: book)
        }
    }
}

#Preview {
    Reader(book: .example1)
}
