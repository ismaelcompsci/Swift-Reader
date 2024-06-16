//
//  LibraryView.swift
//  Read
//
//  Created by Mirna Olvera on 3/14/24.
//

import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(AppTheme.self) var theme
    @Environment(Navigator.self) var navigator
    @Environment(UserPreferences.self) private var userPreferences

    @Query var books: [SDBook]

    var body: some View {
        Group {
            if books.isEmpty {
                emptyView
            } else {
                Books(
                    descriptor: sortDescriptor,
                    displayMode: userPreferences.libraryDisplayMode
                )
            }
        }
        .toolbar {
            LibrarySortFilter()
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationBarTitle("Library", displayMode: .large)
    }

    @ViewBuilder
    var emptyView: some View {
        ContentUnavailableView(label: {
            Label("No Books", systemImage: "books.vertical.circle.fill")
        }) {
            Text("Add books to your library.")
        } actions: {
            Button {
                navigator.presentedSheet = .uploadFile
            } label: {
                Text("Get started")
            }
        }
        .tint(theme.tintColor)
    }
}

extension LibraryView {
    struct Books: View {
        @Environment(Navigator.self) var navigator
        var displayMode: LibraryDisplayMode

        @Query var books: [SDBook]

        init(descriptor: FetchDescriptor<SDBook>, displayMode: LibraryDisplayMode) {
            _books = Query(
                descriptor,
                animation: .easeInOut
            )

            self.displayMode = displayMode
        }

        @ViewBuilder
        var collectionButton: some View {
            Button {
                navigator.navigate(to: .collections)
            } label: {
                HStack {
                    Image(systemName: "text.justify.left")
                        .foregroundStyle(.secondary)

                    Text("Collections")

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }

        var body: some View {
            switch displayMode {
            case .grid:
                ScrollView {
                    VStack {
                        Divider()

                        collectionButton
                            .tint(.primary)
                            .padding(.vertical, 3.5)

                        Divider()
                            .padding(.leading, 28)
                    }
                    .padding(.horizontal, 20)

                    BookGrid(sortedBooks: books)
                }

            case .list:
                List {
                    collectionButton

                    BookList(sortedBooks: books)
                }
                .listStyle(.plain)
            }
        }
    }
}

extension LibraryView {
    static func getDescriptor(for sortKey: LibrarySortKeys, with sortOrder: LibrarySortOrder) -> FetchDescriptor<SDBook> {
        switch sortKey {
        case .title:
            return FetchDescriptor<SDBook>(
                sortBy: [
                    SortDescriptor(
                        \.title,
                        order: sortOrder == .ascending ? .forward : .reverse
                    ),
                ]
            )

        case .date:
            return FetchDescriptor<SDBook>(
                sortBy: [
                    SortDescriptor(
                        \.addedAt,
                        order: sortOrder == .ascending ? .forward : .reverse
                    ),
                ]
            )
        case .author:
            return FetchDescriptor<SDBook>(
                sortBy: [
                    SortDescriptor(
                        \.author,
                        order: sortOrder == .ascending ? .forward : .reverse
                    ),
                ]
            )
        case .last_read:
            return FetchDescriptor<SDBook>(
                sortBy: [
                    SortDescriptor(
                        \.lastOpened,
                        order: sortOrder == .ascending ? .forward : .reverse
                    ),
                ]
            )

        case .progress:
            return FetchDescriptor<SDBook>(
                sortBy: [
                    SortDescriptor(
                        \.position?.totalProgression,
                        order: sortOrder == .ascending ? .forward : .reverse
                    ),
                ]
            )
        }
    }

    var sortDescriptor: FetchDescriptor<SDBook> {
        LibraryView.getDescriptor(for: userPreferences.librarySortKey, with: userPreferences.librarySortOrder)
    }
}

#Preview {
    LibraryView()
        .preferredColorScheme(.dark)
        .withPreviewsEnv()
}
