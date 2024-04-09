//
//  BookListItem.swift
//  Read
//
//  Created by Mirna Olvera on 4/5/24.
//

import SwiftUI

struct BookListItem: View {
    var book: Book
    var onEvent: ((BookItemEvent) -> Void)?

    enum TagState {
        case new
        case progress
        case finished
    }

    var showNewTag: Bool {
        book.readingPosition?.progress == nil || book.readingPosition?.progress == 0
    }

    var tagState: TagState {
        if showNewTag {
            return .new
        } else if let position = book.readingPosition {
            if position.progress == 1.0 {
                return .finished
            }
            return .progress
        }

        return .new
    }

    var compactItem: some View {
        HStack(spacing: 12) {
            BookCover(coverPath: book.coverPath)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.gray, lineWidth: 0.2)
                }
                .aspectRatio(contentMode: .fit)
                .frame(width: 62, height: 62 * 1.77)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(book.authors.first?.name ?? "Unkown Author")
                        .font(.footnote)
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
        .background(.black)
    }

    var body: some View {
        NavigationLink {
            BookDetailView(book: book)
        } label: {
            compactItem
        }
        .tint(.primary)
        .contextMenu {
            Button("Share", systemImage: "square.and.arrow.up.fill") {
                showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
            }

            Button("Edit", systemImage: "pencil") {
                onEvent?(.onEdit)
            }

            if book.readingPosition != nil {
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
        let position = book.readingPosition

        return Text("\(Int((position?.progress ?? 0) * 100))%")
            .foregroundStyle(.secondary)
    }

    var newtag: some View {
        Text("NEW")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.indigo)
            .clipShape(.rect(cornerRadius: 8))
    }
}

#Preview {
    BookListItem(book: .example1)
        .preferredColorScheme(.dark)
}
