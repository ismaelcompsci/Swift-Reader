//
//  BookList.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import RealmSwift
import SwiftUI

enum BookItemEvent {
    case onDelete
    case onClearProgress
    case onEdit
    case onNavigate
}

struct BookList: View {
    @Environment(\.realm) var realm
    @Environment(Navigator.self) var navigator

    var sortedBooks: [Book]

    @State var selectedBook: Book?

    var body: some View {
        LazyVStack {
            ForEach(sortedBooks) { book in
                BookListItem(book: book, onEvent: { bookItemEventHandler($0, book) })

                if sortedBooks.last?.id != book.id {
                    Divider()
                }
            }
        }
        .sheet(item: $selectedBook) { book in
            EditDetailsView(book: book)
        }
    }

    func bookItemEventHandler(_ event: BookItemEvent, _ book: Book) {
        switch event {
        case .onDelete:
            let thawedBook = book.thaw()

            if let thawedBook, let bookRealm = thawedBook.realm {
                try! bookRealm.write {
                    bookRealm.delete(thawedBook)
                }

                BookRemover.removeBook(book: book)
            }
        case .onClearProgress:
            let thawedBook = book.thaw()
            try! realm.write {
                if thawedBook?.readingPosition != nil {
                    thawedBook?.readingPosition = nil
                }
            }

        case .onEdit:
            selectedBook = book
        case .onNavigate:
            navigator.navigate(to: .localDetails(book: book))
        }
    }
}

#Preview {
    BookList(sortedBooks: Book.exampleArray)
}
