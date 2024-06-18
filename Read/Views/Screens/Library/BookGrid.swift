//
//  BookGrid.swift
//  Read
//
//  Created by Mirna Olvera on 2/18/24.
//

import SwiftUI

struct BookGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(UserPreferences.self) var preferences

    let sortedBooks: [SDBook]

    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 15)], spacing: 20) {
            ForEach(sortedBooks) { book in
                BookGridItem(book: book)
            }
        }

        Text("\(sortedBooks.count) Books")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .listRowSeparator(.hidden)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 12)
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
                        .font(.subheadline)
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

                    MenuButton(book: book)
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

#Preview {
    ScrollView {
        BookGrid(
            sortedBooks: [
                .init(id: .init(), title: "The Book"),
                .init(id: .init(), title: "The Book2"),
                .init(id: .init(), title: "The Book3"),
                .init(id: .init(), title: "The Book4"),
                .init(id: .init(), title: "The Book5"),
            ]
        )
        .withPreviewsEnv()
    }
}
