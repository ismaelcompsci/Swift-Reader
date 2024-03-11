//
//  ContentView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import RealmSwift
import SwiftUI

enum LibraryDisplayMode: String, Codable {
    case grid
    case list
}

struct ContentView: View {
    @ObservedResults(Book.self) var books

    @EnvironmentObject var editViewModel: EditViewModel
    @EnvironmentObject var appColor: AppColor

    @StateObject var searchDebouncer = SearchDebouncer()

    @State var showUploadFileView: Bool = false

    @AppStorage("LibrarySortKey") var librarySortKey: LibrarySortKeys = .title
    @AppStorage("LibrarySortOrder") var librarySortOrder: LibrarySortOrder = .descending
    @AppStorage("LibraryDisplayMode") var libraryDisplayMode: LibraryDisplayMode = .list

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        // MARK: Search Bar

                        SearchBar(placeholderText: "Search for book...", searchText: $searchDebouncer.searchText)

                        // MARK: Display Mode Buttons

                        Button {
                            libraryDisplayMode = .list

                        } label: {
                            Image(systemName: "list.bullet")
                        }
                        .font(.system(size: 20))
                        .foregroundStyle(libraryDisplayMode == .list ? appColor.accent : .white)

                        Button {
                            libraryDisplayMode = .grid

                        } label: {
                            Image(systemName: "square.grid.2x2")
                        }
                        .font(.system(size: 20))
                        .foregroundStyle(libraryDisplayMode == .grid ? appColor.accent : .white)
                    }

                    HStack {
                        if books.count > 0 {
                            Text(books.count == 1 ? "\(books.count) Book" : "\(books.count) Books")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }

                        LibrarySortPopover(selectedSortKey: $librarySortKey, selectedSortOrder: $librarySortOrder)
                            .padding(.vertical, 8)
                    }

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
                        .tint(appColor.accent)
                    } else {
                        switch libraryDisplayMode {
                        case .grid:
                            BookGrid(sortedBooks: sortedBooks)

                        case .list:
                            BookList(sortedBooks: sortedBooks)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .sheet(isPresented: self.$showUploadFileView, content: {
                UploadFileView()
                    .interactiveDismissDisabled()
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: {
                        SettingsView()
                    }, label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(appColor.accent)
                    })
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.showUploadFileView = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(appColor.accent)
                    }
                }
            }
            .padding(.horizontal, 12)
            .navigationBarTitle("Home", displayMode: .inline)
        }
        .sheet(isPresented: $editViewModel.editBookReady) {
            if let book = editViewModel.book {
                EditDetailsView(book: book)
            }
        }
    }
}

extension ContentView {
    var sortedBooks: [Book] {
        if searchDebouncer.debouncedSearchText.isEmpty {
            return books.sorted { lhs, rhs in
                switch librarySortKey {
                case .title:
                    if librarySortOrder == .descending {
                        return lhs.title > rhs.title
                    } else {
                        return lhs.title < rhs.title
                    }
                case .date:
                    if librarySortOrder == .descending {
                        return lhs.addedAt > rhs.addedAt
                    } else {
                        return lhs.addedAt < rhs.addedAt
                    }
                case .author:
                    if librarySortOrder == .descending {
                        return lhs.authors.first?.name ?? "" > rhs.authors.first?.name ?? ""
                    } else {
                        return lhs.authors.first?.name ?? "" < rhs.authors.first?.name ?? ""
                    }
                case .last_read:
                    if librarySortOrder == .descending {
                        return lhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0) > rhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0)
                    } else {
                        return lhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0) < rhs.readingPosition?.updatedAt ?? Date(timeIntervalSince1970: 0)
                    }
                case .progress:
                    if librarySortOrder == .descending {
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

extension ContentView {
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
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
        .environmentObject(AppColor())
        .environmentObject(OrientationInfo())
        .environmentObject(EditViewModel())
}
