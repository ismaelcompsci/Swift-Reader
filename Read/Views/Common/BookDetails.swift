//
//  BookDetails.swift
//  Read
//
//  Created by Mirna Olvera on 5/9/24.
//

import SwiftUI

struct BookDetails<Content: View>: View {
    @Environment(AppTheme.self) private var theme

    var image: String
    var title: String
    var description: String
    var author: String
    var tags: [String]
    var horizontalPadding: CGFloat = 12

    var button: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 10) {
                BookCover(imageURL: URL(string: image), title: title, author: author)
                    .frame(width: 114, height: 114 * 1.5)
                    .clipShape(.rect(cornerRadius: 6))

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, horizontalPadding)

            MoreText(text: description)
                .tint(theme.tintColor)
                .padding(.horizontal, horizontalPadding)

            button()
                .padding(.horizontal, horizontalPadding)

            if tags.isEmpty == false {
                TagScrollView(tags: tags)
            }
        }
    }
}

#Preview {
    BookDetails(image: "", title: "Test Title of book", description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.", author: "Author Test", tags: ["Horror", "Action", "Test"]) {
        Button("Read") {}
            .buttonStyle(.main)
    }
    .environment(AppTheme.shared)
}
