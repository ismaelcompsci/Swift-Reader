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

    let sortedBooks: Results<Book>

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
            BookManager.shared.delete(book)
        case .onClearProgress:
            book.removeReadingPosition()
        case .onEdit:
            selectedBook = book
        case .onNavigate:
            navigator.navigate(to: .localDetails(book: book))
        }
    }
}

// #Preview {
//    BookList(sortedBooks: Book.exampleArray)
// }
