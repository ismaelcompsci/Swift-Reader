//
//  SearchView.swift
//  Read
//
//  Created by Mirna Olvera on 6/17/24.
//

import SwiftData
import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""

    @Query var books: [SDBook]

    var filtered: [SDBook] {
        guard searchText.isEmpty == false else {
            return []
        }

        return books.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if filtered.isEmpty && searchText.isEmpty == false {
                ContentUnavailableView("No suggestions", systemImage: "magnifyingglass")
            } else {
                List {
                    ForEach(filtered) { book in
                        Row(book: book)
                            .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    }
                }
                .listStyle(.plain)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: searchText.isEmpty)
        .animation(.easeInOut, value: filtered.isEmpty)
        .searchable(text: $searchText)
        .navigationTitle("Search")
    }
}

extension SearchView {
    struct Row: View {
        @Environment(Navigator.self) var navigator
        let book: SDBook

        var isPDF: Bool {
            book.collections.contains(where: { $0.name == "PDFs" })
        }

        var body: some View {
            Button {
                navigator.navigate(to: .localDetails(book: book))
            } label: {
                HStack(spacing: 10) {
                    BookCover(imageURL: book.imagePath, title: book.title, author: book.author)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 46, height: 46 * 1.77)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: 180, alignment: .leading)

                        if let author = book.author {
                            Text(author)
                                .font(.caption)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        HStack(spacing: 2) {
                            Group {
                                Text(isPDF ? "PDF" : "Book")
                                Text("∙")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            switch tagState {
                            case .new:
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.blue)

                                Text("New")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                            case .progress:
                                Text("\(Int((book.position?.totalProgression ?? 0) * 100))% Complete")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                            case .finished:
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)

                                Text("Finished")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }

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
    }
}

#Preview {
    SearchView()
}
