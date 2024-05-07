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
    @Environment(UserPreferences.self) var preferences

    @State var selectedBook: Book?

    @State private var gridWidth = UIScreen.main.bounds.width

    let sortedBooks: Results<Book>
    let spacing: CGFloat = 24

    var body: some View {
        VStack {
            let width = gridWidth
            let cols = CGFloat(preferences.numberOfColumns)
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

// #Preview {
//    BookGrid(sortedBooks: )
// }
