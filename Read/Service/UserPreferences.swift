//
//  UserPreferences.swift
//  Read
//
//  Created by Mirna Olvera on 4/8/24.
//

import Combine
import SwiftUI

@MainActor
@Observable class UserPreferences {
    class Storage {
        @AppStorage("library_sort_key") public var librarySortKey: LibrarySortKeys = .title
        @AppStorage("library_sort_order") public var librarySortOrder: LibrarySortOrder = .descending
        @AppStorage("library_display_mode") public var libraryDisplayMode: LibraryDisplayMode = .list
        @AppStorage("number_of_grid_columns") var numberOfColumns: Int = 2
    }

    public static let shared = UserPreferences()
    private let storage = Storage()

    public var librarySortKey: LibrarySortKeys {
        didSet {
            storage.librarySortKey = librarySortKey
        }
    }

    public var librarySortOrder: LibrarySortOrder {
        didSet {
            storage.librarySortOrder = librarySortOrder
        }
    }

    public var libraryDisplayMode: LibraryDisplayMode {
        didSet {
            storage.libraryDisplayMode = libraryDisplayMode
        }
    }

    public var numberOfColumns: Int {
        didSet {
            storage.numberOfColumns = numberOfColumns
        }
    }

    init() {
        librarySortKey = storage.librarySortKey
        librarySortOrder = storage.librarySortOrder
        libraryDisplayMode = storage.libraryDisplayMode
        numberOfColumns = storage.numberOfColumns
    }

    func reset() {
        librarySortKey = .title
        librarySortOrder = .descending
        libraryDisplayMode = .list
        numberOfColumns = 2
    }
}

public enum LibrarySortKeys: String, CaseIterable {
    case title = "Title"
    case date = "Date"
    case author = "Author"
    case last_read = "Last Read"
    case progress = "Progress"
}

public enum LibrarySortOrder: String {
    case ascending
    case descending
}

public enum LibraryDisplayMode: String, Codable {
    case grid
    case list
}
