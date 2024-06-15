//
//  BookGrid.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import SwiftUI

struct BookGrid: View {
    @Environment(UserPreferences.self) var preferences
    @State private var gridWidth = UIScreen.main.bounds.width

    let sortedBooks: [SDBook]
    let spacing: CGFloat = 24

    var body: some View {
        VStack {
            let width = gridWidth
            let cols = CGFloat(preferences.numberOfColumns)
            let availableWidth = width - (spacing * cols)
            let itemWidth = availableWidth / cols

            LazyVGrid(
                columns: [GridItem(
                    .adaptive(
                        minimum: itemWidth,
                        maximum: itemWidth
                    ), spacing: spacing
                )],
                spacing: spacing
            ) {
                ForEach(sortedBooks) { book in
                    BookGridItem(book: book)
                }
            }
        }
        .readSize { size in
            gridWidth = size.width
        }
    }
}

extension BookGrid {
    struct BookGridItem: View {
        @Environment(Navigator.self) var navigator

        var book: SDBook
        var withTitle: Bool = false

        enum TagState {
            case new
            case progress
            case finished
        }

        var tagState: TagState {
            if book.isFinsihed == true {
                return .finished
            } else if book.position != nil {
                return .progress
            } else {
                return .new
            }
        }

        var cover: some View {
            BookCover(
                imageURL: book.imagePath,
                title: book.title,
                author: book.author
            )
            .aspectRatio(contentMode: .fit)
            .background()
            .background(
                Rectangle()
                    .fill(.white)
                    .padding(.top, 12)
                    .padding(.horizontal, 10)
                    .shadow(
                        color: .gray.opacity(0.5),
                        radius: 6,
                        x: 0,
                        y: 0
                    )
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 4)
            )
            .shadow(radius: 6, x: 0, y: 12)
        }

        var footer: some View {
            VStack(alignment: .leading, spacing: 0) {
                if withTitle == true {
                    Text(book.title)
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                HStack(alignment: .center) {
                    // TODO: MAKE ABSTARCT TO OWN VIEW
                    switch tagState {
                    case .new:
                        newtag
                    case .progress:
                        progress
                    case .finished:
                        finished
                    }

                    Spacer()

                    Menu {
                        if book.isFinsihed == true {
                            Button("Mark as Still Reading", systemImage: "minus.circle") {
                                book.isFinsihed = false
                                book.dateFinished = nil
                            }
                        } else {
                            Button("Mark as Finished", systemImage: "checkmark.circle") {
                                book.isFinsihed = true
                                book.dateFinished = .now
                            }
                        }

                        if book.collections.contains(where: { $0.name == "Want To Read" }) {
                            Button("Remove from Want to Read", systemImage: "minus.circle") {
                                book.removeFromCollection(name: "Want To Read")
                            }
                        } else {
                            Button("Add To Want to Read", systemImage: "text.badge.star") {
                                book.addToCollection(name: "Want To Read")
                            }
                        }

                        Button("Share", systemImage: "square.and.arrow.up.fill") {
                            showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                        }

                        Button("Edit", systemImage: "pencil") {
                            navigator.presentedSheet = .editBookDetails(book: book)
                        }

                        if book.position != nil {
                            Button("Clear progress", systemImage: "clear.fill") {
                                book.removeLocator()
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
        }

        var body: some View {
            VStack {
                Button {
                    navigator.navigate(to: .localDetails(book: book))
                } label: {
                    cover
                }
                .tint(.primary)

                footer
            }
            .foregroundStyle(.primary)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottom
            )
        }

        var finished: some View {
            Text("Finished")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.001)
        }

        var progress: some View {
            let position = book.position?.totalProgression ?? 0

            return Text("\(Int(position * 100))%")
                .foregroundStyle(.secondary)
                .font(.footnote)
                .minimumScaleFactor(0.001)
        }

        var newtag: some View {
            Text("NEW")
                .font(.caption2)
                .minimumScaleFactor(0.001)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.indigo)
                .clipShape(.rect(cornerRadius: 8))
                .foregroundStyle(.white)
        }
    }
}
