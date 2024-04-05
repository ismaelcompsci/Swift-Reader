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
    @State var bookDownloader = BookDownloader()
    @State var sourceManager: SourceManager
    var modelContainer: ModelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppColor())
                .environmentObject(EditViewModel())
                .modelContainer(modelContainer)
                .environment(sourceManager)
                .environment(bookDownloader)
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

extension Color {
    static let accent = Color("Main")
    static let accentBackground = Color("Main").opacity(0.12)

    static let backgroundSecondary = Color(red: 0.10, green: 0.10, blue: 0.10)
}
