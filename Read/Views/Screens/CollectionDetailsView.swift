//
//  CollectionDetailsView.swift
//  Read
//
//  Created by Mirna Olvera on 6/15/24.
//

import SwiftData
import SwiftUI

struct CollectionDetailsView: View {
    @Environment(UserPreferences.self) var userPreferences
    let collection: SDCollection

    var sortedBooks: [SDBook] {
        let books = collection.books.sorted {
            switch userPreferences.librarySortKey {
            case .title:
                return $0.titleNormalized.localizedStandardCompare($1.titleNormalized) == .orderedAscending
            case .author:
                guard let rhsAuthor = $0.author else { return false }
                guard let lhsAuthor = $1.author else { return true }

                return lhsAuthor.localizedStandardCompare(rhsAuthor) == .orderedAscending

            case .progress:
                guard let rhsPosition = $0.position else { return false }
                guard let lhsPosition = $1.position else { return true }

                return (lhsPosition.totalProgression ?? 0) < (rhsPosition.totalProgression ?? 0)

            case .last_read:
                guard let rhsLastOpened = $0.lastOpened else { return false }
                guard let lhsLastOpened = $1.lastOpened else { return true }

                return lhsLastOpened < rhsLastOpened

            case .date:
                return $0.addedAt < $1.addedAt
            }
        }

        if userPreferences.librarySortOrder == .ascending {
            return books
        } else {
            return books.reversed()
        }
    }

    var body: some View {
        Group {
            switch userPreferences.libraryDisplayMode {
            case .grid:
                ScrollView {
                    BookGrid(sortedBooks: sortedBooks)
                }

            case .list:
                List {
                    BookList(sortedBooks: sortedBooks)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            LibrarySortFilter()
        }
    }
}
