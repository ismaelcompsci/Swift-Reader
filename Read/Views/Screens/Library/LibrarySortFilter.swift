//
//  LibrarySortPopover.swift
//  Read
//
//  Created by Mirna Olvera on 2/2/24.
//

import SwiftUI

struct LibrarySortFilter: View {
    @Environment(UserPreferences.self) var userPreferences
    @Environment(Navigator.self) var navigator

    var body: some View {
        @Bindable var userPreferences = userPreferences

        Menu {
            Section("Display Mode") {
                Picker("display mode", selection: $userPreferences.libraryDisplayMode) {
                    Button {
                        withAnimation {
                            userPreferences.libraryDisplayMode = .list
                        }
                    } label: {
                        Label("List", systemImage: "list.bullet")
                    }
                    .tag(LibraryDisplayMode.list)

                    Button {
                        withAnimation {
                            userPreferences.libraryDisplayMode = .grid
                        }
                    } label: {
                        Label("Grid", systemImage: "square.grid.2x2")
                    }
                    .tag(LibraryDisplayMode.grid)
                }
            }

            Divider()

            Section("Filter") {
                Picker("Sort", selection: $userPreferences.librarySortKey) {
                    ForEach(LibrarySortKeys.allCases, id: \.rawValue) { sort in
                        Button {
                            userPreferences.librarySortKey = sort
                        } label: {
                            Text("\(sort.rawValue)")
                        }
                        .tag(sort)
                    }
                }
            }

            Divider()

            Button {
                if userPreferences.librarySortOrder == .ascending {
                    userPreferences.librarySortOrder = .descending
                } else {
                    userPreferences.librarySortOrder = .ascending
                }

            } label: {
                if userPreferences.librarySortOrder == .ascending {
                    Label("Ascending", systemImage: "checkmark")
                } else {
                    Text("Ascending")
                }
            }

            Button {
                navigator.presentedSheet = .uploadFile
            } label: {
                Label("Add Book", systemImage: "plus")
            }

        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .labelStyle(.iconOnly)
                .symbolVariant(.fill)
                .symbolRenderingMode(.hierarchical)
        }
    }
}
