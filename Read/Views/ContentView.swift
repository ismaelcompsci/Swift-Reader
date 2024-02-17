//
//  ContentView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import RealmSwift
import SwiftUI

struct HomeBookList: View {
    var realm = try! Realm()

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

                            Text(book.authors.first?.name ?? "Unkown Author")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        }

                        if let position = book.readingPosition {
                            Spacer()

                            HStack {
                                PieProgress(progress: position.progress ?? 0.0)
                                    .frame(width: 22)

                                Text("\(Int((position.progress ?? 0) * 100))%")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: 61, alignment: .leading)
                    .background(.black)
                    .contextMenu {
                        Button("Share", systemImage: "square.and.arrow.up.fill") {
                            showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                        }
                        if book.readingPosition != nil {
                            Button("Clear progress", systemImage: "clear.fill") {
                                let thawedBook = book.thaw()
                                try! realm.write {
                                    if thawedBook?.readingPosition != nil {
                                        thawedBook?.readingPosition = nil
                                    }
                                }
                            }
                        }
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
    var realm = try! Realm()

    var sortedBooks: [Book]
    var realmBooks: ObservedResults<Book>

    let bookHeight: CGFloat = 120
    let bookWidth: CGFloat = 90

    let size: CGFloat = 120
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: size))],
            spacing: 8
        ) {
            ForEach(sortedBooks) { book in
                let image = getBookCover(path: book.coverPath) ?? UIImage()
                NavigationLink(destination: BookDetailView(book: book)) {
                    VStack {
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .blur(radius: 8, opaque: true)
                                .frame(width: bookWidth, height: bookHeight)
                                .aspectRatio(contentMode: .fill)

                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: bookWidth, height: bookHeight)
                        }
                        .cornerRadius(6)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.gray, lineWidth: 0.2)
                        }
                        .overlay {
                            if let position = book.readingPosition {
                                PieProgress(progress: position.progress ?? 0.0)
                                    .frame(width: 22)
                                    .position(x: bookWidth, y: 0)
                            }
                        }

                        Text(book.title)
                            .lineLimit(1)

                        Text(book.authors.first?.name ?? "Unkown Author")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .contextMenu {
                        Button("Share", systemImage: "square.and.arrow.up.fill") {
                            showShareSheet(url: URL.documentsDirectory.appending(path: book.bookPath!))
                        }
                        if book.readingPosition != nil {
                            Button("Clear progress", systemImage: "clear.fill") {
                                let thawedBook = book.thaw()
                                try! realm.write {
                                    if thawedBook?.readingPosition != nil {
                                        thawedBook?.readingPosition = nil
                                    }
                                }
                            }
                        }
                        Button("Delete", systemImage: "trash.fill", role: .destructive) {
                            realmBooks.remove(book)
                            BookRemover.removeBook(book: book)
                        }
                    }
                }
            }
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
                                    withAnimation(.smooth) {
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
