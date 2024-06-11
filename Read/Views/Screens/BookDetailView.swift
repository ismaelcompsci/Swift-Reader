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
            BookDetails(
                image: getCoverFullPath(for: book.coverPath ?? "").absoluteString,
                title: book.title,
                description: book.summary ?? "",
                author: book.author ?? "Unknown Author",
                tags: book.tags.map { $0.name }
            ) {
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
            }
        }
        .navigationTitle(book.title)
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
