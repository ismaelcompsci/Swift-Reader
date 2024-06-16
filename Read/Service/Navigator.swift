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
        }
    }
}

public enum TabNavigation: String, Hashable, CaseIterable {
    case library = "Library"
    case discover = "Discover"
    case search = "Search"
    case settings = "Settings"
    case readingNow = "Reading Now"

    var icon: String {
        switch self {
        case .library:
            "books.vertical.fill"
        case .discover:
            "shippingbox"
        case .search:
            "magnifyingglass"
        case .settings:
            "gear"
        case .readingNow:
            "book.fill"
        }
    }
}

@Observable
public class Navigator {
    public var path: [NavigatorDestination] = []
    public var sideMenuTab: TabNavigation = .library

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
            }
        }
    }
}
