//
//  ReadApp.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SwiftData
import SwiftUI

func Log(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n")
{
    let output = items.map { "SR_LOG: \($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
}

@main
struct ReadApp: App {
    @State var bookDownloader = BookDownloader.shared
    @State var sourceManager: SourceManager
    @State var theme = AppTheme.shared
    @State var userPreferences = UserPreferences.shared
    @State var toaster = Toaster.shared
    @State var navigator = Navigator()

    var modelContainer: ModelContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(sourceManager)
                .environment(bookDownloader)
                .environment(theme)
                .environment(userPreferences)
                .environment(toaster)
                .environment(navigator)
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

extension View {
    func withNavigator() -> some View {
        navigationDestination(for: NavigatorDestination.self) { destination in
            switch destination {
            case .localDetails(book: let book):
                BookDetailView(book: book)
            case .sourceSearch(search: let search):
                SourceSearch(searchText: search)
            }
        }
    }
}
