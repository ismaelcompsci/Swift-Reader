//
//  BookGrid.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import RealmSwift
import SwiftUI

struct BookGrid: View {
    @Environment(\.realm) var realm

    var sortedBooks: [Book]

    let bookHeight: CGFloat = 120
    let bookWidth: CGFloat = 90

    let size: CGFloat = 120
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: size))],
            spacing: 8
        ) {
            ForEach(sortedBooks) { book in
                let image = getBookCover(path: book.coverPath)

                NavigationLink(destination: BookDetailView(book: book)) {
                    VStack {
                        ZStack {
                            if let image {
                                Image(uiImage: image)
                                    .resizable()
                                    .blur(radius: 8, opaque: true)
                                    .frame(width: bookWidth, height: bookHeight)
                                    .aspectRatio(contentMode: .fill)

                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: bookWidth, height: bookHeight)
                            } else {
                                VStack {
                                    Image(systemName: "book.pages.fill")
                                        .resizable()
                                        .frame(width: bookWidth / 2, height: bookHeight / 2)
                                }
                                .frame(width: bookWidth, height: bookHeight)
                            }
                        }
                        .cornerRadius(6)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.gray, lineWidth: 0.2)
                        }
                        .overlay {
                            if let position = book.readingPosition {
                                PieProgress(progress: position.progress ?? 0.0)
                                    .frame(width: 22)
                                    .position(x: bookWidth, y: 0)
                            }
                        }

                        Text(book.title)
                            .lineLimit(1)

                        Text(book.authors.first?.name ?? "Unkown Author")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .contextMenu {
                        Button("Share", systemImage: "square.and.arrow.up.fill") {
                            showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                        }
                        if book.readingPosition != nil {
                            Button("Clear progress", systemImage: "clear.fill") {
                                let thawedBook = book.thaw()
                                try! realm.write {
                                    if thawedBook?.readingPosition != nil {
                                        thawedBook?.readingPosition = nil
                                    }
                                }
                            }
                        }
                        Button("Delete", systemImage: "trash.fill", role: .destructive) {
                            let thawedBook = book.thaw()

                            if let thawedBook, let bookRealm = thawedBook.realm {
                                try! bookRealm.write {
                                    bookRealm.delete(thawedBook)
                                }

                                BookRemover.removeBook(book: book)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    BookGrid(sortedBooks: Book.exampleArray)
        .environment(\.realmConfiguration, MockRealms.config)
}
