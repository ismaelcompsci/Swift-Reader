//
//  BookGrid.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import RealmSwift
import SwiftUI

struct BookGrid: View {
    @Environment(\.realm) var realm
    @Environment(Navigator.self) var navigator

    @State var selectedBook: Book?

    @State private var gridWidth = UIScreen.main.bounds.width
    @AppStorage("numberOfGridColumns") var numberOfColumns: Int = 2

    var sortedBooks: [Book]
    let spacing: CGFloat = 24

    var body: some View {
        VStack {
            let width = gridWidth
            let cols = CGFloat(numberOfColumns)
            let availableWidth = width - (spacing * cols)
            let itemWidth = availableWidth / cols

            LazyVGrid(
                columns: [GridItem(
                    .adaptive(
                        minimum: itemWidth,
                        maximum: itemWidth
                    ), spacing: spacing
                )],
                spacing: spacing
            ) {
                ForEach(sortedBooks) { book in

                    BookGridItem(book: book) { event in
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
            }
        }
        .readSize { size in
            gridWidth = size.width
        }
        .sheet(item: $selectedBook) { book in
            EditDetailsView(book: book)
        }
    }
}

#Preview {
    BookGrid(sortedBooks: Book.exampleArray)
}
