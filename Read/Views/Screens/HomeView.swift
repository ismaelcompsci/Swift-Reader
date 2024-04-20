//
//  HomeView.swift
//  Read
//
//  Created by Mirna Olvera on 3/14/24.
//

import RealmSwift
import SwiftUI

struct HomeView: View {
    @ObservedResults(Book.self) var books

    @Environment(AppTheme.self) var theme
    @Environment(UserPreferences.self) private var userPreferences

    @StateObject var searchDebouncer = SearchDebouncer()

    @State var showUploadFileView: Bool = false

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
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.showUploadFileView = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.tintColor)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .padding(.horizontal, 12)
        .navigationBarTitle("Home", displayMode: .inline)
        .sheet(isPresented: self.$showUploadFileView, content: {
            UploadFileView()
                .interactiveDismissDisabled()
        })
    }
}

extension HomeView {
    var sortedBooks: [Book] {
        if searchDebouncer.debouncedSearchText.isEmpty {
            return books.sorted { lhs, rhs in
                switch userPreferences.librarySortKey {
                case .title:
                    if userPreferences.librarySortOrder == .descending {
                        return lhs.title > rhs.title
                    } else {
                        return lhs.title < rhs.title
                    }
                case .date:
                    if userPreferences.librarySortOrder == .descending {
                        return lhs.addedAt > rhs.addedAt
                    } else {
                        return lhs.addedAt < rhs.addedAt
                    }
                case .author:
                    if userPreferences.librarySortOrder == .descending {
                        return lhs.authors.first?.name ?? "" > rhs.authors.first?.name ?? ""
                    } else {
                        return lhs.authors.first?.name ?? "" < rhs.authors.first?.name ?? ""
                    }
                case .last_read:
                    if userPreferences.librarySortOrder == .descending {
                        return lhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0) > rhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0)
                    } else {
                        return lhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0) < rhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0)
                    }
                case .progress:
                    if userPreferences.librarySortOrder == .descending {
                        return lhs.readingPosition?.progress ?? 0 > rhs.readingPosition?.progress ?? 0
                    } else {
                        return lhs.readingPosition?.progress ?? 0 < rhs.readingPosition?.progress ?? 0
                    }
                }
            }
        } else {
            return books.filter { $0.title.lowercased().contains(searchDebouncer.debouncedSearchText.lowercased()) }
        }
    }
}

extension HomeView {
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
    HomeView()
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
}
