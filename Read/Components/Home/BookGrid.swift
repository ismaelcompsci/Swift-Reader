//
//  BookGrid.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import RealmSwift
import SwiftUI

struct BookGridItem: View {
    var book: Book
    let onEvent: (ListItemEvent) -> Void

    let bookHeight: CGFloat = 170
    let bookWidth: CGFloat = 115

    var compactBookView: some View {
        VStack {
            ZStack {
                BookCover(coverPath: book.coverPath)
                    .frame(width: bookWidth, height: bookHeight)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.gray, lineWidth: 0.3)
            }
            .overlay {
                if let position = book.readingPosition {
                    PieProgress(progress: position.progress ?? 0.0)
                        .frame(width: 22)
                        .position(x: bookWidth - 5, y: 0)
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
    }

    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            compactBookView
                .contextMenu {
                    Button("Share", systemImage: "square.and.arrow.up.fill") {
                        showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                    }
                    if book.readingPosition != nil {
                        Button("Clear progress", systemImage: "clear.fill") {
                            onEvent(.onClearProgress)
                        }
                    }
                    Button("Delete", systemImage: "trash.fill", role: .destructive) {
                        onEvent(.onDelete)
                    }
                } preview: {
                    HStack {
                        BookCover(coverPath: book.coverPath)
                            .frame(width: bookWidth, height: bookHeight)

                        VStack(alignment: .leading) {
                            Text(book.title)
                                .lineLimit(1)

                            Text(book.authors.first?.name ?? "Unkown Author")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .lineLimit(1)

                            Spacer()

                            if let position = book.readingPosition {
                                Text("\(Int((position.progress ?? 0) * 100))% last read \(position.updatedAt.formatted(.relative(presentation: .numeric)))")
                                    .foregroundStyle(.gray)

                            } else {
                                Text("Added on \(book.addedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: bookHeight * 1.2)
                    .padding()
                    .background(.black)
                }
        }
    }
}

struct BookGrid: View {
    @Environment(\.realm) var realm

    var sortedBooks: [Book]

    let size: CGFloat = 120
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: size))],
            spacing: 8
        ) {
            ForEach(sortedBooks) { book in

                BookGridItem(book: book) { event in
                    switch event {
                    case .onDelete:
                        let thawedBook = book.thaw()

                        if let thawedBook, let bookRealm = thawedBook.realm {
                            try! bookRealm.write {
                                bookRealm.delete(thawedBook)
                            }

                            BookRemover.removeBook(book: book)
                        }
                    case .onClearProgress:
                        let thawedBook = book.thaw()
                        try! realm.write {
                            if thawedBook?.readingPosition != nil {
                                thawedBook?.readingPosition = nil
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
