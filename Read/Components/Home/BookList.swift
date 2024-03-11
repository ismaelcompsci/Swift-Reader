//
//  BookList.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import RealmSwift
import SwiftUI

enum BookItemEvent {
    case onDelete
    case onClearProgress
    case onEdit
}

struct BookListItem: View {
    var book: Book
    let onEvent: (BookItemEvent) -> Void

    private var bookWidth: CGFloat {
        60
    }

    private var bookHeight: CGFloat {
        90
    }

    var compactBookView: some View {
        HStack {
            BookCover(coverPath: book.coverPath)
                .frame(width: bookWidth, height: bookHeight)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.gray, lineWidth: 0.2)
                }

            VStack(alignment: .leading) {
                Text(book.title)
                    .lineLimit(3)
                    .font(.title3)
                    .multilineTextAlignment(.leading)

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
        .padding(.vertical, 4)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black)
    }

    var body: some View {
        NavigationLink(destination: {
            BookDetailView(book: book)
        }) {
            compactBookView
                .contextMenu {
                    Button("Share", systemImage: "square.and.arrow.up.fill") {
                        showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                    }

                    Button("Edit", systemImage: "pencil") {
                        onEvent(.onEdit)
                    }

                    if book.readingPosition != nil {
                        Button("Clear progress", systemImage: "clear.fill") {
                            onEvent(.onClearProgress)
                        }
                    }

                    Button("Delete", systemImage: "trash.fill", role: .destructive) {
                        onEvent(.onDelete)
                    }
                }
        }
    }
}

struct BookList: View {
    @EnvironmentObject var editViewModel: EditViewModel
    @Environment(\.realm) var realm
    var sortedBooks: [Book]

    var body: some View {
        LazyVStack {
            ForEach(sortedBooks) { book in

                BookListItem(book: book) { event in
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

                    case .onEdit:
                        editViewModel.reset()

                        editViewModel.book = book
                        editViewModel.showEditView = true
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
