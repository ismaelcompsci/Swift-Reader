//
//  LastEngaged.swift
//  Read
//
//  Created by Mirna Olvera on 5/6/24.
//

import SwiftData
import SwiftUI

var descriptor: FetchDescriptor<SDBook> {
    var descriptor = FetchDescriptor<SDBook>(
        predicate: #Predicate<SDBook> { book in
            book.lastEngaged != nil
        },
        sortBy: [SortDescriptor(\.lastEngaged, order: .reverse)]
    )

    descriptor.fetchLimit = 4
    return descriptor
}

struct LastEngaged: View {
    @Query(descriptor) var lastEngagedBooks: [SDBook]

    var body: some View {
        if lastEngagedBooks.isEmpty == false {
            ScrollView(.horizontal) {
                LazyHGrid(rows: [
                    GridItem(.flexible(minimum: 184))
                ]) {
                    if let firstBook = lastEngagedBooks.first {
                        VStack(alignment: .leading) {
                            Text("Current")
                                .font(.headline)
                                .fontDesign(.serif)

                            BookGrid.BookGridItem(book: firstBook, withTitle: true)
                        }
                        .frame(maxWidth: 184)
                    }

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

                            BookGrid.BookGridItem(book: book, withTitle: true)
                        }
                        .frame(maxWidth: 184)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .contentMargins(.vertical, 12, for: .scrollContent)
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .frame(maxHeight: 386)
        }
    }
}
