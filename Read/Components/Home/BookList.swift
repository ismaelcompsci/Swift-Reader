//
//  BookList.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import RealmSwift
import SwiftUI

struct BookList: View {
    @Environment(\.realm) var realm

    var sortedBooks: [Book]

    var body: some View {
        ForEach(sortedBooks) { book in

            VStack {
                NavigationLink(destination: {
                    BookDetailView(book: book)
                }) {
                    HStack {
                        BookCover(coverPath: book.coverPath)
                            .frame(width: 34.5, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.gray, lineWidth: 0.2)
                            }

                        VStack(alignment: .leading) {
                            Text(book.title)
                                .lineLimit(1)

                            Text(book.authors.first?.name ?? "Unkown Author")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        }

                        if let position = book.readingPosition {
                            Spacer()

                            HStack {
                                PieProgress(progress: position.progress ?? 0.0)
                                    .frame(width: 22)

                                Text("\(Int((position.progress ?? 0) * 100))%")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 61, alignment: .leading)
                    .background(.black)
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

                if sortedBooks.last?.id != book.id {
                    Divider()
                }
            }
        }
    }
}

#Preview {
    BookList(sortedBooks: Book.exampleArray)
//        .environment(\.realmConfiguration, MockRealms.config)
}
