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
    @State var bookDownloader = BookDownloader.shared
    @State var sourceManager: SourceManager
    @State var theme = AppTheme.shared
    @State var userPreferences = UserPreferences.shared

    var modelContainer: ModelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(sourceManager)
                .environment(bookDownloader)
                .environment(theme)
                .environment(userPreferences)
                .preferredColorScheme(.dark)
                .environment(\.font, Font.custom("Poppins-Regular", size: 16))
        }
    }

    init() {
        do {
            modelContainer = try ModelContainer(for: Source.self)

            let sourceManager = SourceManager(modelContext: modelContainer.mainContext)
            _sourceManager = State(initialValue: sourceManager)
        } catch {
            fatalError("Failed to create ModelContainer for Source")
        }
    }
}
