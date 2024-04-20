//
//  BookGridItem.swift
//  Read
//
//  Created by Mirna Olvera on 4/6/24.
//

import SwiftUI

struct BookGridItem: View {
    var book: Book
    let onEvent: (BookItemEvent) -> Void

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
