//
//  SourceBookCard.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

struct SourceBookCard: View {
    var book: PartialSourceBook
    var sourceId: String

    var body: some View {
        NavigationLink {
            SourceBookDetailsView(sourceId: self.sourceId, item: self.book)
        } label: {
            VStack {
                SourceBookImage(imageUrl: self.book.image)
                    .frame(width: 130 * 0.6, height: 130)

                Text(self.book.title)
                    .lineLimit(1)

                Text(self.book.author ?? "Unknown Author")
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .frame(width: 130)
        }
        .tint(.white)
    }
}

#Preview {
    SourceBookCard(book: PartialSourceBook(id: "", title: ""), sourceId: "")
}
