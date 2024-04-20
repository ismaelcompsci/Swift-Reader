//
//  ContentView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SimpleToast
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
            .toolbarBackground(.black, for: .navigationBar)
        }
        .simpleToast(
            isPresented: $toaster.showToast,
            options: toaster.toastSettings)
        {
            HStack {
                Image(systemName: toaster.toastImage)
                Text(toaster.toastMessage)
                    .lineLimit(2)

                Spacer()

                Button {
                    toaster.dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(toaster.toastColor)
            .clipShape(.rect(cornerRadius: 10))
            .padding(.horizontal)
            .foregroundColor(.white)
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

            Button {
                withAnimation(.snappy) {
                    navigator.sideMenuTab = .home
                    showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "house")
                    Text("Home")
                        .foregroundStyle(navigator.sideMenuTab == .home ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                withAnimation(.snappy) {
                    navigator.sideMenuTab = .settings
                    showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                        .foregroundStyle(navigator.sideMenuTab == .settings ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                withAnimation(.snappy) {
                    navigator.sideMenuTab = .discover
                    showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "shippingbox")
                    Text("Discover")
                        .foregroundStyle(navigator.sideMenuTab == .discover ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                withAnimation(.snappy) {
                    navigator.sideMenuTab = .search
                    showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                        .foregroundStyle(navigator.sideMenuTab == .search ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
