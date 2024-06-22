//
//  Menu.swift
//  Read
//
//  Created by Mirna Olvera on 6/16/24.
//

import SwiftUI

struct MenuButton: View {
    @Environment(Navigator.self) var navigator
    let book: SDBook

    var body: some View {
        Menu {
            Button("Share", systemImage: "square.and.arrow.up.fill") {
                showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
            }

            Divider()

            if book.collections.contains(where: { $0.name == "Want To Read" }) {
                Button("Remove from Want to Read", systemImage: "minus.circle") {
                    try? BookManager.shared.removeFromCollection(book: book, name: "Want To Read")
                }
            } else {
                Button("Add To Want to Read", systemImage: "text.badge.star") {
                    try? BookManager.shared.addToCollection(book: book, name: "Want To Read")
                }
            }

            Button("Add To Collection", systemImage: "text.badge.plus") {
                navigator.presentedSheet = .addToCollection(book: book)
            }

            if book.isFinished == true {
                Button("Mark as Still Reading", systemImage: "minus.circle") {
                    book.isFinished = false
                    book.dateFinished = nil

                    try? BookManager.shared.removeFromCollection(book: book, name: "Finished")
                }
            } else {
                Button("Mark as Finished", systemImage: "checkmark.circle") {
                    book.isFinished = true
                    book.dateFinished = .now

                    try? BookManager.shared.addToCollection(book: book, name: "Finished")
                }
            }

            Divider()

            Button("Edit", systemImage: "pencil") {
                navigator.presentedSheet = .editBookDetails(book: book)
            }

            if book.position != nil {
                Button("Clear progress", systemImage: "clear.fill") {
                    book.removeLocator()
                }
            }

            Divider()

            if let path = navigator.path.last {
                if case .collectionDetails(let collection) = path {
                    switch collection.name {
                    case "Books", "PDFs", "Want To Read":
                        EmptyView()
                    default:
                        Button("Remove From \(collection.name)", systemImage: "text.badge.minus", role: .destructive) {
                            print("REMOVING FROM \(collection.name)")
                        }
                    }
                }
            }

            Button("Delete", systemImage: "trash.fill", role: .destructive) {
                BookManager.shared.delete(book)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .padding(.vertical, 10)
                .foregroundStyle(.secondary)
        }
    }
}
