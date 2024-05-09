//
//  BookGridItem.swift
//  Read
//
//  Created by Mirna Olvera on 4/6/24.
//

import SwiftUI

struct BookGridItem: View {
    var book: Book
    var withTitle: Bool = false
    let onEvent: (BookItemEvent) -> Void

    enum TagState {
        case new
        case progress
        case finished
    }

    var showNewTag: Bool {
        book.readingPosition?.progress == nil
    }

    var tagState: TagState {
        if book.lists.contains(.completed) {
            return .finished
        } else if book.readingPosition != nil {
            return .progress
        } else {
            return .new
        }
    }

    var cover: some View {
        BookCover(
            coverPath: book.coverPath,
            title: book.title,
            author: book.authors.first?.name
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
                    if book.lists.contains(where: { $0 == .completed }) {
                        Button("Mark as Still Reading", systemImage: "minus.circle") {
                            onEvent(.onAddToList(.wantToRead))
                        }
                    } else {
                        Button("Mark as Finished", systemImage: "checkmark.circle") {
                            onEvent(.onAddToList(.completed))
                        }
                    }

                    if book.lists.contains(where: { $0 == .wantToRead }) {
                        Button("Remove from Want to Read", systemImage: "minus.circle") {
                            onEvent(.onAddToList(.wantToRead))
                        }
                    } else {
                        Button("Add To Want to Read", systemImage: "text.badge.star") {
                            onEvent(.onAddToList(.wantToRead))
                        }
                    }

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
                onEvent(.onNavigate)
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
        let position = book.readingPosition

        return Text("\(Int((position?.progress ?? 0) * 100))%")
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

#Preview {
    BookGridItem(book: .example1, onEvent: { _ in })
        .frame(width: 120, height: 120 * 1.6)
        .preferredColorScheme(.dark)
}
