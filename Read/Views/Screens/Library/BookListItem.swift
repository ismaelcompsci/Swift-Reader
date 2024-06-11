//
//  BookListItem.swift
//  Read
//
//  Created by Mirna Olvera on 4/5/24.
//

import SwiftUI

struct BookListItem: View {
    var book: SDBook
    var onEvent: ((BookItemEvent) -> Void)?

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

    var compactItem: some View {
        HStack(spacing: 12) {
            BookCover(
                imageURL: getCoverFullPath(for: book.coverPath ?? ""),
                title: book.title,
                author: book.author
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.gray, lineWidth: 0.2)
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 62, height: 62 * 1.77)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 3, y: 5)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(book.author ?? "Unkown Author")
                        .font(.footnote)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                HStack(alignment: .center) {
                    switch tagState {
                    case .new:
                        newtag
                    case .progress:
                        progress
                    case .finished:
                        finished
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background()
    }

    var body: some View {
        Button {
            onEvent?(.onNavigate)
        } label: {
            compactItem
        }
        .tint(.primary)
        .contextMenu {
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
                    onEvent?(.onRemoveFromList("Want To Read"))
                }
            } else {
                Button("Add To Want to Read", systemImage: "text.badge.star") {
                    onEvent?(.onAddToList("Want To Read"))
                }
            }

            Button("Share", systemImage: "square.and.arrow.up.fill") {
                showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
            }

            Button("Edit", systemImage: "pencil") {
                onEvent?(.onEdit)
            }

            if book.position != nil {
                Button("Clear progress", systemImage: "clear.fill") {
                    onEvent?(.onClearProgress)
                }
            }

            Button("Delete", systemImage: "trash.fill", role: .destructive) {
                onEvent?(.onDelete)
            }
        }
    }

    var finished: some View {
        Text("Finished")
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.indigo)
            .clipShape(.rect(cornerRadius: 8))
            .foregroundStyle(.white)
    }
}

#Preview {
    BookListItem(
        book: SDBook(
            id: .init(),
            title: "Unknown Title"
        )
    )
    .preferredColorScheme(.dark)
}
