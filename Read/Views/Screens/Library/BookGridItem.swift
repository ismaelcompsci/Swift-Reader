//
//  BookGridItem.swift
//  Read
//
//  Created by Mirna Olvera on 4/6/24.
//

import SwiftUI

struct BookGridItem: View {
    var book: SDBook
    var withTitle: Bool = false
    let onEvent: (BookItemEvent) -> Void

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
            imageURL: getCoverFullPath(for: book.coverPath ?? ""),
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
                            onEvent(.onRemoveFromList("Want To Read"))
                        }
                    } else {
                        Button("Add To Want to Read", systemImage: "text.badge.star") {
                            onEvent(.onAddToList("Want To Read"))
                        }
                    }

                    Button("Share", systemImage: "square.and.arrow.up.fill") {
                        showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                    }

                    Button("Edit", systemImage: "pencil") {
                        onEvent(.onEdit)
                    }

                    if book.position != nil {
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

#Preview {
    BookGridItem(book: SDBook(
        id: .init(),
        title: "Unknown Title"
    ),
    onEvent: {
        _ in
    })
    .frame(width: 120, height: 120 * 1.6)
    .preferredColorScheme(.dark)
}
