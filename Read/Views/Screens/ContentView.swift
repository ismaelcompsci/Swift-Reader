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

    @State var showMenu = false

    var body: some View {
        @Bindable var toaster = toaster
        @Bindable var navigator = navigator

        NavigationStack(path: $navigator.path) {
            Group {
                switch navigator.sideMenuTab {
                case .settings:
                    SettingsView()
                case .discover:
                    SourcesDiscoverView()
                case .home:
                    HomeView()
                case .search:
                    SourceSearch()
                }
            }
            .withNavigator()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.snappy) {
                            showMenu = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(theme.tintColor)
                    }
                }
            }
            .toolbarBackground(.background, for: .navigationBar)
        }
        .sideMenu(isShowing: $showMenu) {
            sideMenu
        }
    }

    var sideMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()

                SRXButton {
                    withAnimation(.snappy) {
                        showMenu = false
                    }
                }
            }

            ForEach(SideMenuNavigation.allCases, id: \.self) { nav in

                Button {
                    withAnimation(.snappy) {
                        navigator.sideMenuTab = nav
                        showMenu = false
                    }
                } label: {
                    HStack {
                        Image(systemName: nav.icon)

                        Text(nav.rawValue)
                            .foregroundStyle(navigator.sideMenuTab == nav ? theme.tintColor : .white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()
        }
        .tint(theme.tintColor)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
}
