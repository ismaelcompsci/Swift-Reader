//
//  AddToCollectionView.swift
//  Read
//
//  Created by Mirna Olvera on 6/16/24.
//

import SwiftData
import SwiftUI

struct AddToCollectionView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(AppTheme.self) var theme

    @Query var collections: [SDCollection]

    @State var editMode = false
    @State var newCollectionName = ""
    @FocusState private var inputFocused: Bool

    let book: SDBook

    func createCollection() {
        guard newCollectionName.isEmpty == false else {
            inputFocused = false
            editMode = false
            return
        }

        let name = newCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)

        let newCollection = SDCollection(
            name: name,
            books: []
        )

        modelContext.insert(newCollection)
        inputFocused = false
        editMode = false
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(collections) { collection in
                    CollectionRow(collection: collection, book: book)
                }

                addCollectionButton
            }
            .listStyle(.plain)
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var addCollectionButton: some View {
        Button {
            withAnimation {
                editMode = true
                inputFocused = true
            }
        } label: {
            if editMode {
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
                HStack {
                    Label("New Collection...", systemImage: "plus")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension AddToCollectionView {
    struct CollectionRow: View {
        @Environment(Navigator.self) var navigator
        var collection: SDCollection
        let book: SDBook

        var body: some View {
            Button {
                collection.books.append(book)
                book.collections.append(collection)
                navigator.presentedSheet = nil
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
            .disabled(collection.addable == false)
        }
    }
}

#Preview {
    AddToCollectionView(book: .init(id: .init(), title: "The book"))
}
