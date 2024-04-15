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
            imageUrl: self.book.image,
            title: book.title,
            author: book.author
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(.gray, lineWidth: 0.2)
        }
        .aspectRatio(contentMode: .fit)
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
        VStack {
            Spacer()

            // TODO: SWITCH TO NAVIGATOR
            NavigationLink {
                SourceBookDetailsView(sourceId: self.sourceId, item: self.book)
            } label: {
                cover
            }

            footer
        }
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
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .bottom
        )
        .frame(width: 130, height: 130 * 1.7)
    }
}

#Preview {
    SourceBookCard(
        book: PartialSourceBook(
            id: "",
            title: "The End is here",
            author: "Author name"
        ),
        sourceId: ""
    )
}
