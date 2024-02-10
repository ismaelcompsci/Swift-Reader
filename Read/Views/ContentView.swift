//
//  ContentView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import RealmSwift
import SwiftUI

func getBookCover(path imagePath: String?) -> UIImage? {
    if let imgPath = imagePath {
        let documentsPath = URL.documentsDirectory
        let fullImagePath = documentsPath.appending(path: imgPath)

        do {
            let data = try Data(contentsOf: fullImagePath)

            return UIImage(data: data)

        } catch {
            print("DATA RERRr")
        }

        if let image = UIImage(contentsOfFile: fullImagePath.absoluteString) {
            return image
        }

        return UIImage(named: "default")
    } else {
        return UIImage(named: "default")
    }
}

struct HomeBookList: View {
    var sortedBooks: [Book]
    var realmBooks: ObservedResults<Book>

    var body: some View {
        ForEach(sortedBooks) { book in
            VStack {
                NavigationLink(destination: {
                    BookDetailView(book: book)
                }) {
                    HStack {
                        Image(uiImage: getBookCover(path: book.coverPath) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34.5, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading) {
                            Text(book.title)
                                .lineLimit(1)

                            Text(book.author.first?.name ?? "Unkown Author")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        }

                        if let position = book.readingPosition {
                            Spacer()

                            HStack {
                                Spacer()

                                Text("\(Int((position.progress ?? 0) * 100))%")
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 61, alignment: .leading)
                    .background(.black)
                    .contextMenu {
                        Button("Delete", systemImage: "trash.fill", role: .destructive) {
                            realmBooks.remove(book)
                            BookRemover.removeBook(book: book)
                        }
                    }
                }

                if sortedBooks.last?.id != book.id {
                    Divider()
                }
            }
        }
    }
}

struct HomeBookGrid: View {
    var sortedBooks: [Book]
    var realmBooks: ObservedResults<Book>

    let size: CGFloat = 120

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: size))],
            spacing: 8)
        {
            ForEach(sortedBooks) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    VStack {
                        Image(uiImage: getBookCover(path: book.coverPath) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 109, height: 111)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(book.title)
                            .lineLimit(1)

                        Text(book.author.first?.name ?? "Unkown Author")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 120, maxHeight: 160)
                    .contextMenu {
                        Button("Delete", systemImage: "trash.fill", role: .destructive) {
                            realmBooks.remove(book)
                            BookRemover.removeBook(book: book)
                        }
                    }
                }
            }
            .animation(.easeOut, value: sortedBooks)
        }
    }
}

enum LibraryDisplayMode: String, Codable {
    case grid
    case list
}

struct ContentView: View {
    @ObservedResults(Book.self) var books
    @State var showUploadFileView: Bool = false
    @State var searchText = ""
    @AppStorage("LibrarySortKey") var librarySortKey: LibrarySortKeys = .title
    @AppStorage("LibrarySortOrder") var librarySortOrder: LibrarySortOrder = .descending
    @AppStorage("LibraryDisplayMode") var libraryDisplayMode: LibraryDisplayMode = .list

    var sortedBooks: [Book] {
        if searchText.isEmpty {
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
                        return lhs.author.first?.name ?? "" > rhs.author.first?.name ?? ""
                    } else {
                        return lhs.author.first?.name ?? "" < rhs.author.first?.name ?? ""
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
            return books.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    HStack {
                        // MARK: Search Bar

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.accent)
                            TextField("Search for book...", text: $searchText)

                            if !searchText.isEmpty {
                                Button {
                                    withAnimation {
                                        searchText = ""
                                    }
                                } label: {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundStyle(Color.accent)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.backgroundSecondary)
                        .clipShape(.capsule)

                        Button {
                            withAnimation {
                                libraryDisplayMode = .list
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                        .font(.system(size: 20))
                        .foregroundStyle(libraryDisplayMode == .list ? Color.accent : .white)

                        Button {
                            withAnimation {
                                libraryDisplayMode = .grid
                            }
                        } label: {
                            Image(systemName: "square.grid.2x2")
                        }
                        .font(.system(size: 20))
                        .foregroundStyle(libraryDisplayMode == .grid ? Color.accent : .white)
                    }

                    LibrarySortPopover(selectedSortKey: $librarySortKey, selectedSortOrder: $librarySortOrder)
                        .padding(.vertical, 8)

                    if libraryDisplayMode == .list {
                        HomeBookList(sortedBooks: sortedBooks, realmBooks: $books)
                            .animation(.easeOut, value: books)

                    } else {
                        HomeBookGrid(sortedBooks: sortedBooks, realmBooks: $books)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .sheet(isPresented: self.$showUploadFileView, content: {
                UploadFileView()
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.showUploadFileView = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accent)
                    }
                }
            }
            .padding(.horizontal, 12)
            .navigationBarTitle("Home", displayMode: .inline)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
