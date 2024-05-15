//
//  BookGrid.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import SwiftUI

struct BookGrid: View {
    @Environment(Navigator.self) var navigator
    @Environment(UserPreferences.self) var preferences
    
    @State var selectedBook: SDBook?
    
    @State private var gridWidth = UIScreen.main.bounds.width
    
    let sortedBooks: [SDBook]
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
