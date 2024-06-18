//
//  BookDetailView.swift
//  Read
//
//  Created by Mirna Olvera on 1/30/24.
//

import SwiftUI

struct BookDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppTheme.self) var theme

    var book: SDBook

    @State private var openReader = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .bottom, spacing: 10) {
                    BookCover(imageURL: book.imagePath, title: book.title, author: book.author)
                        .frame(width: 114, height: 114 * 1.5)
                        .clipShape(.rect(cornerRadius: 6))

                    VStack(alignment: .leading) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(book.author ?? "Unknown Author")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)

                if let summary = book.summary {
                    MoreText(text: summary)
                        .tint(theme.tintColor)
                        .padding(.horizontal, 12)
                }

                Button {
                    withAnimation(.spring()) {
                        openReader = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "book.fill")

                        if book.position != nil {
                            Text("Continue Reading \(Int((book.position?.totalProgression ?? 0) * 100))%")
                        } else {
                            Text("Read")
                        }
                    }
                }
                .buttonStyle(.main)
                .padding(.horizontal, 12)

                if book.tags.isEmpty == false {
                    TagScrollView(tags: book.tags.map { $0.name })
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.vertical, 24, for: .scrollContent)
        .fullScreenCover(isPresented: $openReader, content: {
            Reader(book: book)
        })
    }
}

#Preview {
    BookDetailView(book: SDBook(id: .init(), title: "Unknown Title"))
        .environment(AppTheme.shared)
}
