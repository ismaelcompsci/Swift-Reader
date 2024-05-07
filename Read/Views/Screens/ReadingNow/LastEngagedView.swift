//
//  LastEngagedView.swift
//  Read
//
//  Created by Mirna Olvera on 5/6/24.
//

import RealmSwift
import SwiftUI

struct LastEngagedView: View {
    @Environment(\.realm) var realm
    @State private var recentBooks: [Book] = []

    var body: some View {
        ScrollView(.horizontal) {
            if recentBooks.isEmpty == false {
                LazyHStack(spacing: 12) {
                    if let firstBook = recentBooks.first {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.headline)
                                .fontDesign(.serif)

                            BookGridItem(book: firstBook) { _ in
                            }
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

                                BookGridItem(book: book) { _ in
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.vertical, 12, for: .scrollContent)
        .contentMargins(.horizontal, 12, for: .scrollContent)
        .frame(maxHeight: 300)
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

        return Array(sortedLastEngagedBooks.prefix(through: 3))
    }
}
