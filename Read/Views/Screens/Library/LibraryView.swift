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
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(Navigator.self) var navigator

    @StateObject var searchDebouncer = SearchDebouncer()
    @Query var books: [SDBook]

    var body: some View {
        @Bindable var userPreferences = userPreferences

        ScrollView {
            LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                Section {
                    if books.count == 0 {
                        // MARK: EMPTY VIEW

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

                    } else {
                        Books(
                            descriptor: sortDescriptor,
                            displayMode: userPreferences.libraryDisplayMode
                        )
                    }
                } header: {
                    VStack {
                        homeHeader

                        HStack {
                            if books.count > 0 {
                                Text(books.count == 1 ? "\(books.count) Book" : "\(books.count) Books")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }

                            LibrarySortPopover(
                                selectedSortKey: $userPreferences.librarySortKey,
                                selectedSortOrder: $userPreferences.librarySortOrder
                            )
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.vertical, 4)
                    .background()
                }
            }
            .padding(.horizontal, 12)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navigator.presentedSheet = .uploadFile
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.tintColor)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationBarTitle("Library", displayMode: .large)
    }

    var homeHeader: some View {
        HStack {
            SearchBar(placeholderText: "Search for book...", searchText: $searchDebouncer.searchText)

            // MARK: Display Mode Buttons

            Button {
                userPreferences.libraryDisplayMode = .list

            } label: {
                Image(systemName: "list.bullet")
            }
            .font(.system(size: 20))
            .foregroundStyle(userPreferences.libraryDisplayMode == .list ? theme.tintColor : .primary)

            Button {
                userPreferences.libraryDisplayMode = .grid

            } label: {
                Image(systemName: "square.grid.2x2")
            }
            .font(.system(size: 20))
            .foregroundStyle(userPreferences.libraryDisplayMode == .grid ? theme.tintColor : .primary)
        }
    }
}

extension LibraryView {
    struct Books: View {
        var displayMode: LibraryDisplayMode

        @Query var books: [SDBook]

        init(descriptor: FetchDescriptor<SDBook>, displayMode: LibraryDisplayMode) {
            _books = Query(
                descriptor,
                animation: .easeInOut
            )

            self.displayMode = displayMode
        }

        var body: some View {
            switch displayMode {
            case .grid:
                BookGrid(sortedBooks: books)

            case .list:
                BookList(sortedBooks: books)
            }
        }
    }
}

extension LibraryView {
    var sortDescriptor: FetchDescriptor<SDBook> {
        if searchDebouncer.debouncedSearchText.isEmpty {
            switch userPreferences.librarySortKey {
            case .title:

                return FetchDescriptor<SDBook>(
                    sortBy: [
                        SortDescriptor(
                            \.title,
                            order: userPreferences.librarySortOrder == .ascending ? .forward : .reverse
                        ),
                    ]
                )

            case .date:
                return FetchDescriptor<SDBook>(
                    sortBy: [
                        SortDescriptor(
                            \.addedAt,
                            order: userPreferences.librarySortOrder == .ascending ? .forward : .reverse
                        ),
                    ]
                )
            case .author:
                return FetchDescriptor<SDBook>(
                    sortBy: [
                        SortDescriptor(
                            \.author,
                            order: userPreferences.librarySortOrder == .ascending ? .forward : .reverse
                        ),
                    ]
                )
            case .last_read:
                return FetchDescriptor<SDBook>(
                    sortBy: [
                        SortDescriptor(
                            \.lastOpened,
                            order: userPreferences.librarySortOrder == .ascending ? .forward : .reverse
                        ),
                    ]
                )

            case .progress:
                return FetchDescriptor<SDBook>(
                    sortBy: [
                        SortDescriptor(
                            \.position?.totalProgression,
                            order: userPreferences.librarySortOrder == .ascending ? .forward : .reverse
                        ),
                    ]
                )
            }
        } else {
            let title = searchDebouncer
                .debouncedSearchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            return FetchDescriptor<SDBook>(
                predicate: #Predicate<SDBook> { book in
                    book.title.localizedStandardContains(title)
                }
            )
        }
    }
}

extension LibraryView {
    class SearchDebouncer: ObservableObject {
        @Published var searchText = "" {
            didSet {
                // force update on debounce if text is empty
                if searchText.isEmpty {
                    debouncedSearchText = ""
                }
            }
        }

        @Published var debouncedSearchText = ""

        init() {
            debouncedSearchText = searchText

            $searchText
                .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                .assign(to: &$debouncedSearchText)
        }
    }
}

#Preview {
    LibraryView()
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
}
