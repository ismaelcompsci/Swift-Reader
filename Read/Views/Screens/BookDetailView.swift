//
//  BookDetailView.swift
//  Read
//
//  Created by Mirna Olvera on 1/30/24.
//

import RealmSwift
import SwiftUI

struct BookDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme
    @Environment(\.colorScheme) var colorScheme

    var book: Book

    @State private var openReader = false

    var body: some View {
        ScrollView {
            BookDetails(
                image: getCoverFullPath(for: book.coverPath ?? "").absoluteString,
                title: book.title,
                description: book.summary ?? "",
                author: book.authors.first?.name ?? "Unknown Author",
                tags: book.tags.map { $0.name }
            ) {
                SRButton(systemName: "book.fill", text: book.readingPosition != nil ? "Continue Reading \(Int((book.readingPosition?.progress ?? 0.0) * 100))%" : "Read") {
                    withAnimation(.spring()) {
                        openReader = true
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(isPresented: $openReader, content: {
            Reader(book: book)
        })
    }
}

#Preview {
    BookDetailView(book: .shortExample)
        .environment(AppTheme.shared)
}
