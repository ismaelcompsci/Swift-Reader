//
//  ContentView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(Toaster.self) private var toaster
    @Environment(Navigator.self) private var navigator

    init() {
        let appearance = UINavigationBarAppearance()

        appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
        appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]

        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance

        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some View {
        @Bindable var toaster = toaster
        @Bindable var navigator = navigator

        NavigationStack(path: $navigator.path) {
            Group {
                TabView(selection: $navigator.sideMenuTab) {
                    NavigationView {
                        ReadingNowView()
                    }
                    .tag(TabNavigation.readingNow)
                    .tabItem {
                        Label(TabNavigation.readingNow.rawValue, systemImage: TabNavigation.readingNow.icon)
                    }

                    NavigationView {
                        LibraryView()
                    }
                    .tag(TabNavigation.library)
                    .tabItem {
                        Label("Library", systemImage: TabNavigation.library.icon)
                    }

                    NavigationView {
                        SettingsView()
                    }
                    .tag(TabNavigation.settings)
                    .tabItem {
                        Label("Settings", systemImage: TabNavigation.settings.icon)
                    }
                }
            }
            .withNavigator()
            .withSheetDestinations(sheetDestinations: $navigator.presentedSheet)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .applyTheme(AppTheme.shared)
        .withPreviewsEnv()
}
