//
//  LastEngaged.swift
//  Read
//
//  Created by Mirna Olvera on 5/6/24.
//

import RealmSwift
import SwiftUI

struct LastEngaged: View {
    @Environment(Navigator.self) var navigator

    @ObservedResults(
        Book.self,
        filter: NSPredicate(format: "lastEngaged != nil"),
        sortDescriptor: SortDescriptor(keyPath: "lastEngaged", ascending: false)
    ) var lastEngagedBooks

    @State var selectedBook: Book?

    var body: some View {
        ScrollView(.horizontal) {
            if lastEngagedBooks.isEmpty == false {
                LazyHStack(spacing: 12) {
                    if let firstBook = lastEngagedBooks.first {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.headline)
                                .fontDesign(.serif)

                            BookGridItem(book: firstBook, withTitle: true) { event in
                                handleBookItemEvent(firstBook, event)
                            }
                            .frame(width: 300 / 1.6, height: 300)
                        }
                    }

                    if lastEngagedBooks.count > 1 {
                        ForEach(lastEngagedBooks.dropFirst()) { book in
                            VStack(alignment: .leading) {
                                if lastEngagedBooks.dropFirst().first == book {
                                    Text("Recent")
                                        .font(.headline)
                                        .fontDesign(.serif)
                                } else {
                                    Text("")
                                        .frame(height: 17)
                                }

                                BookGridItem(book: book, withTitle: true) { event in
                                    handleBookItemEvent(book, event)
                                }
                                .frame(width: 300 / 1.6, height: 300)
                            }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.vertical, 12, for: .scrollContent)
        .contentMargins(.horizontal, 24, for: .scrollContent)
        .sheet(item: $selectedBook) { book in
            EditDetailsView(book: book)
        }
    }

    func handleBookItemEvent(_ book: Book, _ event: BookItemEvent) {
        switch event {
        case .onDelete:
            BookManager.shared.delete(book)
        case .onClearProgress:
            book.removeReadingPosition()
        case .onEdit:
            selectedBook = book
        case .onNavigate:
            navigator.navigate(to: .localDetails(book: book))
        case .onAddToList(let list):
            book.addToList(list)
        }
    }
}
