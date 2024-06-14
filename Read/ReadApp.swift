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
                .environment(\.font, Font.custom("Poppins-Regular", size: 16))
                .applyTheme(theme)
        }
    }

    init() {
        do {
            let schema = Schema([SDBook.self])
            modelContainer = try ModelContainer(for: schema)

            BookManager.shared.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer for Source")
        }
    }
}
