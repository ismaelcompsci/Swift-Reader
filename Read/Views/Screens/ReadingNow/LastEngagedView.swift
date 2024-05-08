//
//  LastEngagedView.swift
//  Read
//
//  Created by Mirna Olvera on 5/6/24.
//

import RealmSwift
import SwiftUI

struct LastEngagedView: View {
    @Environment(Navigator.self) var navigator
    @Environment(\.realm) var realm

    @ObservedResults(
        Book.self,
        filter: NSPredicate(format: "lastEngaged != nil"),
        sortDescriptor: SortDescriptor(stringLiteral: "lastEngaged")
    ) var lastEngagedBooks

    @State private var recentBooks: [Book] = []
    @State var selectedBook: Book?

    var body: some View {
        ScrollView(.horizontal) {
            if recentBooks.isEmpty == false {
                LazyHStack(spacing: 12) {
                    if let firstBook = recentBooks.first {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.headline)
                                .fontDesign(.serif)

                            BookGridItem(book: firstBook) { event in
                                handleBookItemEvent(firstBook, event)
                            }
                            .frame(height: 300)
                        }
                    }

                    if recentBooks.count > 1 {
                        ForEach(recentBooks.dropFirst()) { book in
                            VStack(alignment: .leading) {
                                if recentBooks.dropFirst().first == book {
                                    Text("Recent")
                                        .font(.headline)
                                        .fontDesign(.serif)
                                } else {
                                    Text("")
                                        .frame(height: 17)
                                }

                                BookGridItem(book: book) { event in
                                    handleBookItemEvent(book, event)
                                }
                                .frame(height: 300)
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
        .onAppear {
            recentBooks = getRecentBooks()
        }
    }

    func getRecentBooks() -> [Book] {
        let books = realm.objects(Book.self)

        let hasRead = books.filter { $0.lastEngaged != nil }

        let sortedLastEngagedBooks = hasRead.sorted { lhs, rhs in
            lhs.lastEngaged! > rhs.lastEngaged!
        }

        if sortedLastEngagedBooks.count < 3 {
            return sortedLastEngagedBooks
        }

        return Array(sortedLastEngagedBooks.prefix(through: 3))
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
