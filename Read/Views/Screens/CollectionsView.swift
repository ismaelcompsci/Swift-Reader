//
//  Collections.swift
//  Read
//
//  Created by Mirna Olvera on 6/15/24.
//

import SwiftData
import SwiftUI

struct CollectionsView: View {
    @Query var collections: [SDCollection]

    var body: some View {
        List {
            ForEach(collections) { collection in
                CollectionRow(collection: collection)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.large)
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
