//
//  SourceBookCard.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

struct SourceBookCard: View {
    @Environment(Navigator.self) var navigator
    var book: PartialSourceBook
    var sourceId: String

    var author: String {
        if let author = book.author {
            return author.isEmpty ? "Unknown Author" : author
        }

        return "Unknown Author"
    }

    var title: String {
        book.title.isEmpty ? "Unknown Title" : book.title
    }

    var cover: some View {
        SourceBookImage(
            imageUrl: book.image,
            title: book.title,
            author: book.author
        )
        .aspectRatio(contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(.gray, lineWidth: 0.2)
        }
        .frame(width: 130, height: 130 * 1.7, alignment: .bottom)
    }

    var footer: some View {
        VStack {
            Text(title)
                .lineLimit(1)

            Text(author)
                .lineLimit(1)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                navigator.navigate(to: .sourceBookDetails(sourceId: sourceId, item: book))
            } label: {
                cover
            }
            footer
        }
        .frame(
            maxWidth: 130,
            maxHeight: .infinity,
            alignment: .bottom
        )
        .tint(.white)
        .contextMenu {
            let lastPath = navigator.path.last
            let id = lastPath?.id ?? UUID().uuidString

            if navigator.sideMenuTab != .search && id != "sourceSearch" {
                Button("Search for book") {
                    navigator.navigate(to: .sourceSearch(search: book.title))
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        HStack {
            Text("HELLO")
                .font(.headline)

            Spacer()
        }

        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                SourceBookCard(
                    book: PartialSourceBook(
                        id: "",
                        title: "The End is here The End is here The End is here The End is here ",
                        author: "Author name"
                    ),
                    sourceId: ""
                )

                SourceBookCard(
                    book: PartialSourceBook(
                        id: "",
                        title: "The End is here",
                        image: "https://s3proxy.cdn-zlib.se//covers299/collections/userbooks/8eb4a3e656f1da578081966d6c26ebbdca84b4b10906f5eb511e8c57cf20807f.jpg",
                        author: "Author name"
                    ),
                    sourceId: ""
                )

                SourceBookCard(
                    book: PartialSourceBook(
                        id: "",
                        title: "The End is here",
                        image: "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1433161048i/1137215.jpg", author: "Author name"
                    ),
                    sourceId: ""
                )

                SourceBookCard(
                    book: PartialSourceBook(
                        id: "",
                        title: "The End is here",
                        image: "https://s3proxy.cdn-zlib.se//covers299/collections/userbooks/64a1a6951391ec8b702874ed321b40a368e81d564e30b05105564a0fa1762920.jpg", author: "Author name"
                    ),
                    sourceId: ""
                )
            }
        }
        .contentMargins(10, for: .scrollContent)
        .listRowInsets(EdgeInsets())
    }
    .environment(Navigator())
}
