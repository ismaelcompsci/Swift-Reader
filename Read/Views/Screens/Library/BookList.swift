//
//  BookList.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import SwiftUI

enum BookItemEvent {
    case onDelete
    case onClearProgress
    case onEdit
    case onNavigate
    case onAddToList(String)
    case onRemoveFromList(String)
}

struct BookList: View {
    @Environment(Navigator.self) var navigator

    let sortedBooks: [SDBook]

    @State var selectedBook: SDBook?

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

    func bookItemEventHandler(_ event: BookItemEvent, _ book: SDBook) {
        switch event {
        case .onDelete:
            BookManager.shared.delete(book)
        case .onClearProgress:
            book.removePosition()
        case .onEdit:
            selectedBook = book
        case .onNavigate:
            navigator.navigate(to: .localDetails(book: book))
        case .onAddToList(let list):
            book.addToCollection(name: list)
        case .onRemoveFromList(let list):
            book.removeFromCollection(name: list)
        }
    }
}
