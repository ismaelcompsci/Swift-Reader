//
//  WantToRead.swift
//  Read
//
//  Created by Mirna Olvera on 5/9/24.
//

import RealmSwift
import SwiftUI

struct WantToRead: View {
    @ObservedResults(
        Book.self,
        filter: NSPredicate(
            format: "ANY lists CONTAINS %@",
            ListName.wantToRead.rawValue
        )
    ) var wantToReadBooks

    var handleBookItemEvent: ((Book, BookItemEvent) -> Void)?

    var body: some View {
        if wantToReadBooks.isEmpty == false {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Want To Read")
                            .font(.headline)
                            .fontDesign(.serif)

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }

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
                            BookGridItem(book: book, withTitle: false, onEvent: { event in
                                handleBookItemEvent?(book, event)
                            })
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