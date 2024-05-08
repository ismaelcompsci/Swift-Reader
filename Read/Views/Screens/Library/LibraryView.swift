//
//  LibraryView.swift
//  Read
//
//  Created by Mirna Olvera on 3/14/24.
//

import RealmSwift
import SwiftUI

struct LibraryView: View {
    @ObservedResults(Book.self) var books

    @Environment(AppTheme.self) var theme
    @Environment(UserPreferences.self) private var userPreferences

    @StateObject var searchDebouncer = SearchDebouncer()

    @State var showUploadFileView: Bool = false

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
                                showUploadFileView = true
                            } label: {
                                Text("Get started")
                            }
                        }
                        .tint(theme.tintColor)

                    } else {
                        switch userPreferences.libraryDisplayMode {
                        case .grid:
                            BookGrid(sortedBooks: sortedBooks)

                        case .list:
                            BookList(sortedBooks: sortedBooks)
                        }
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
                    showUploadFileView = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.tintColor)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationBarTitle("Library", displayMode: .large)
        .sheet(isPresented: self.$showUploadFileView, content: {
            UploadFileView()
                .interactiveDismissDisabled()
        })
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
    var sortedBooks: RealmSwift.Results<Book> {
        if searchDebouncer.debouncedSearchText.isEmpty {
            switch userPreferences.librarySortKey {
            case .title:
                return books.sorted(by: \.title, ascending: userPreferences.librarySortOrder == .ascending)
            case .date:
                return books.sorted(by: \.addedAt, ascending: userPreferences.librarySortOrder == .ascending)
            case .author:
                return books.sorted(by: \.authors.first?.name, ascending: userPreferences.librarySortOrder == .ascending)
            case .last_read:
                return books.sorted(by: \.readingPosition?.updatedAt, ascending: userPreferences.librarySortOrder == .ascending)
            case .progress:
                return books.sorted(by: \.readingPosition?.progress, ascending: userPreferences.librarySortOrder == .ascending)
            }
        } else {
            return books.filter(
                "title CONTAINS[cd] %@",
                searchDebouncer.debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
