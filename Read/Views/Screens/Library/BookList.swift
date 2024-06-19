//
//  BookList.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import SwiftUI

struct BookList: View {
    @Environment(Navigator.self) var navigator
    let sortedBooks: [SDBook]

    var body: some View {
        Section {
            ForEach(sortedBooks) { book in
                BookRow(book: book)
                    .tint(.primary)
                    .modifier(ContextMenuModifier(navigator: navigator, book: book))
            }

            Text("\(sortedBooks.count) Books")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .listRowSeparator(.hidden)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

extension BookList {
    struct BookRow: View {
        @Environment(Navigator.self) var navigator
        var book: SDBook

        var body: some View {
            Button {
                navigator.navigate(to: .localDetails(book: book))
            } label: {
                HStack(spacing: 12) {
                    BookCover(
                        imageURL: book.imagePath,
                        title: book.title,
                        author: book.author
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.gray, lineWidth: 0.2)
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 62, height: 62 * 1.77)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 3, y: 5)

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading) {
                            Text(book.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Text(book.author ?? "Unkown Author")
                                .font(.caption2)
                                .lineLimit(2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        InfoTag(book: book)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
