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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init() {
        let appearance = UINavigationBarAppearance()

        appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
        appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]

        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance

        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }

    @ViewBuilder
    var tabBarView: some View {
        @Bindable var navigator = navigator

        NavigationStack(path: $navigator.path) {
            TabView(selection: $navigator.tab) {
                ForEach(TabNavigation.allCases, id: \.self) { tab in
                    NavigationView {
                        navigator.tab.makeContentView()
                    }
                    .tag(tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var sideBarView: some View {
        @Bindable var navigator = navigator

        NavigationSplitView {
            List {
                ForEach(TabNavigation.allCases, id: \.self) { tab in
                    Button {
                        navigator.tab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
        } detail: {
            NavigationStack(path: $navigator.path) {
                navigator.tab.makeContentView()
                    .withNavigator()
            }
        }
    }

    var body: some View {
        @Bindable var toaster = toaster
        @Bindable var navigator = navigator

        Group {
            if horizontalSizeClass == .compact {
                tabBarView
            } else {
                sideBarView
            }
        }
        .withSheetDestinations(sheetDestinations: $navigator.presentedSheet)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .applyTheme(AppTheme.shared)
        .withPreviewsEnv()
}
