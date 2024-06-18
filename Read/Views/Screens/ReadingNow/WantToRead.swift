//
//  WantToRead.swift
//  Read
//
//  Created by Mirna Olvera on 5/9/24.
//

import SwiftData
import SwiftUI

struct WantToRead: View {
    @Environment(Navigator.self) var navigator

    @Query(filter: #Predicate<SDBook> { book in
        book.collections.contains(where: { $0.name == "Want To Read" })
    }, animation: .easeInOut) var wantToReadBooks: [SDBook]

    var body: some View {
        if wantToReadBooks.isEmpty == false {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading) {
                    Button {
                        if let wantToReadCollection = wantToReadBooks.first?.collections.first(where: { $0.name == "Want To Read" }) {
                            navigator.navigate(to: .collectionDetails(collection: wantToReadCollection))
                        }
                    } label: {
                        HStack {
                            Text("Want To Read")
                                .font(.title3)
                                .fontDesign(.serif)
                                .fontWeight(.semibold)

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                    }
                    .tint(.primary)

                    Text("Books you'd like to read next.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 24)

                ScrollView(.horizontal) {
                    LazyHGrid(rows: [GridItem(
                        .fixed(
                            300
                        )
                    )]) {
                        ForEach(wantToReadBooks) { book in
                            BookGrid.BookGridItem(book: book, withTitle: false)
                                .frame(maxHeight: 300)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .animation(.easeInOut, value: wantToReadBooks)
                .contentMargins(.horizontal, 24, for: .scrollContent)
                .scrollIndicators(.hidden)
            }
            .padding(.vertical, 28)
            .background(
                LinearGradient(
                    colors: [Color(hex: "1E1E1E"), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

#Preview {
    WantToRead()
}
