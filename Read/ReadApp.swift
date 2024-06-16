//
//  ReadApp.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SwiftData
import SwiftUI

@main
struct ReadApp: App {
    @State var theme = AppTheme.shared
    @State var userPreferences = UserPreferences.shared
    @State var toaster = Toaster.shared
    @State var navigator = Navigator()

    var modelContainer: ModelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(theme)
                .environment(userPreferences)
                .environment(toaster)
                .environment(navigator)
                .applyTheme(theme)
        }
    }

    init() {
        do {
            let schema = Schema([SDBook.self])
            modelContainer = try ModelContainer(for: schema)
            BookManager.shared.modelContext = modelContainer.mainContext

            var collectionFetchDescriptor = FetchDescriptor<SDCollection>()
            collectionFetchDescriptor.fetchLimit = 1

            let collectionEmpty = try modelContainer.mainContext.fetch(collectionFetchDescriptor).isEmpty

            if collectionEmpty {
                let defaultCollections = [
                    SDCollection(createdAt: .now, name: "Want To Read", books: [], icon: "arrow.right.circle.fill"),
                    SDCollection(createdAt: .now, name: "Finished", books: [], icon: "checkmark.circle.fill"),
                    SDCollection(createdAt: .now, name: "Books", books: [], icon: "book.fill"),
                    SDCollection(createdAt: .now, name: "PDFs", books: [], icon: "doc.text.fill"),
                ]

                for collection in defaultCollections {
                    modelContainer.mainContext.insert(collection)
                }

                try modelContainer.mainContext.save()
            }
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }
}
