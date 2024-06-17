//
//  Collections.swift
//  Read
//
//  Created by Mirna Olvera on 6/15/24.
//

import SwiftData
import SwiftUI

struct CollectionsView: View {
    @Environment(AppTheme.self) var theme
    @Environment(\.modelContext) var modelContext

    @Query var collections: [SDCollection]

    @State var addingCollectionMode = false
    @State var newCollectionName = ""
    @FocusState var inputFocused: Bool

    var body: some View {
        List {
            ForEach(collections) { collection in
                CollectionRow(collection: collection)
                    .deleteDisabled(collection.removable == false)
            }
            .onDelete(perform: onDelete)

            addCollectionButton
        }
        .listStyle(.plain)
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            EditButton()
        }
    }

    @ViewBuilder
    var addCollectionButton: some View {
        Button {
            withAnimation {
                addingCollectionMode = true
                inputFocused = true
            }
        } label: {
            if addingCollectionMode {
                LabeledContent {
                    TextField("", text: $newCollectionName)
                        .focused($inputFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            createCollection()
                        }
                        .padding(.leading, 4)

                } label: {
                    Image(systemName: "text.justify.left")
                        .foregroundStyle(theme.tintColor)
                        .font(.title2)
                }

            } else {
                Label("New Collection...", systemImage: "plus")
            }
        }
    }

    func onDelete(_ indexSet: IndexSet) {
        for index in indexSet {
            let collection = collections[index]

            modelContext.delete(collection)
        }
    }

    func createCollection() {
        guard newCollectionName.isEmpty == false else {
            inputFocused = false
            addingCollectionMode = false
            return
        }

        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)

        let newCollection = SDCollection(
            name: name,
            books: []
        )

        modelContext.insert(newCollection)
        inputFocused = false
        addingCollectionMode = false
        newCollectionName = ""
    }
}

extension CollectionsView {
    struct CollectionRow: View {
        @Environment(Navigator.self) var navigator

        let collection: SDCollection

        var body: some View {
            Button {
                navigator.navigate(to: .collectionDetails(collection: collection))
            } label: {
                HStack {
                    Label(collection.name, systemImage: collection.icon)

                    Spacer()

                    if collection.books.isEmpty == false {
                        Text("\(collection.books.count)")
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    CollectionsView()
}
