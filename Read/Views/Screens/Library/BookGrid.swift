//
//  BookGrid.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import SwiftUI

struct BookGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(UserPreferences.self) var preferences

    let sortedBooks: [SDBook]

    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 15)], spacing: 20) {
            ForEach(sortedBooks) { book in
                BookGridItem(book: book)
            }
        }

        Text("\(sortedBooks.count) Books")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .listRowSeparator(.hidden)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 12)
    }
}

extension BookGrid {
    struct BookGridItem: View {
        @Environment(Navigator.self) var navigator

        var book: SDBook
        var withTitle: Bool = false

        @ViewBuilder
        var cover: some View {
            BookCover(
                imageURL: book.imagePath,
                title: book.title,
                author: book.author
            )
            .aspectRatio(contentMode: .fit)
            .clipShape(
                RoundedRectangle(cornerRadius: 4)
            )
        }

        var footer: some View {
            VStack(alignment: .leading, spacing: 0) {
                if withTitle == true {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                HStack(alignment: .center) {
                    InfoTag(book: book)

                    Spacer()

                    MenuButton(book: book)
                }
            }
        }

        var body: some View {
            VStack {
                Button {
                    navigator.navigate(to: .localDetails(book: book))
                } label: {
                    cover
                }
                .tint(.primary)

                footer
            }
            .foregroundStyle(.primary)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottom
            )
        }
    }
}

#Preview {
    ScrollView {
        BookGrid(
            sortedBooks: [
                .init(id: .init(), title: "The Book"),
                .init(id: .init(), title: "The Book2"),
                .init(id: .init(), title: "The Book3"),
                .init(id: .init(), title: "The Book4"),
                .init(id: .init(), title: "The Book5"),
            ]
        )
        .withPreviewsEnv()
    }
}
