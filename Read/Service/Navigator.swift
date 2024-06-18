//
//  Navigator.swift
//  Read
//
//  Created by Mirna Olvera on 4/13/24.
//

import Foundation
import SwiftUI

public enum NavigatorDestination: Hashable {
    case localDetails(book: SDBook)
    case collections
    case collectionDetails(collection: SDCollection)

    var id: String {
        switch self {
        case .localDetails:
            "localDetails"
        case .collections:
            "collections"
        case .collectionDetails:
            "collectionDetails"
        }
    }
}

public enum SheetDestination: Identifiable, Hashable {
    case editBookDetails(book: SDBook)
    case uploadFile
    case addToCollection(book: SDBook)

    public static func == (lhs: SheetDestination, rhs: SheetDestination) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var id: String {
        switch self {
        case .editBookDetails:
            return "edit-book-details"
        case .uploadFile:
            return "upload-file"
        case .addToCollection:
            return "addToCollection"
        }
    }
}

@MainActor
public enum TabNavigation: String, Hashable, @preconcurrency CaseIterable, Identifiable {
    case readingNow = "Reading Now"
    case library = "Library"
    case search = "Search"
    case settings = "Settings"

    public nonisolated var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .library:
            "books.vertical.fill"
        case .search:
            "magnifyingglass"
        case .settings:
            "gear"
        case .readingNow:
            "book.fill"
        }
    }

    @ViewBuilder
    func makeContentView() -> some View {
        switch self {
        case .readingNow:
            ReadingNowView()
        case .library:
            LibraryView()
        case .search:
            SearchView()
        case .settings:
            SettingsView()
        }
    }
}

@Observable
public class Navigator {
    public var path: [NavigatorDestination] = []
    public var tab: TabNavigation = .library

    public var presentedSheet: SheetDestination?

    public init() {}

    public func navigate(to: NavigatorDestination) {
        path.append(to)
    }
}

extension View {
    func withNavigator() -> some View {
        navigationDestination(for: NavigatorDestination.self) { destination in
            switch destination {
            case .localDetails(book: let book):
                BookDetailView(book: book)
            case .collections:
                CollectionsView()
            case .collectionDetails(collection: let collection):
                CollectionDetailsView(collection: collection)
            }
        }
    }

    func withSheetDestinations(sheetDestinations: Binding<SheetDestination?>) -> some View {
        sheet(item: sheetDestinations) { destination in
            switch destination {
            case .editBookDetails(let book):
                EditDetailsView(book: book)
            case .uploadFile:
                UploadFileView()
            case .addToCollection(book: let book):
                AddToCollectionView(book: book)
            }
        }
    }
}
