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

    @State var showMenu = false
    @State var navigation: SideMenuNavigation = .home

    enum SideMenuNavigation: String {
        case home = "Home"
        case settings = "Settings"
        case discover = "Discover"
        case search = "Search"
    }

    var body: some View {
        @Bindable var toaster = toaster

        NavigationStack {
            Group {
                switch navigation {
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.snappy) {
                            self.showMenu = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(self.theme.tintColor)
                    }
                }
            }
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
            .background(toaster.toastColor.opacity(0.8))
            .clipShape(.rect(cornerRadius: 10))
            .padding(.horizontal)
            .foregroundColor(.white)
        }
        .sideMenu(isShowing: self.$showMenu) {
            self.sideMenu
        }
    }

    var sideMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()

                SRXButton {
                    withAnimation(.snappy) {
                        self.showMenu = false
                    }
                }
            }

            Button {
                withAnimation(.snappy) {
                    navigation = .home
                    self.showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "house")
                    Text("Home")
                        .foregroundStyle(navigation == .home ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                withAnimation(.snappy) {
                    self.navigation = .settings
                    self.showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                        .foregroundStyle(navigation == .settings ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                withAnimation(.snappy) {
                    self.navigation = .discover
                    self.showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "shippingbox")
                    Text("Discover")
                        .foregroundStyle(navigation == .discover ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                withAnimation(.snappy) {
                    self.navigation = .search
                    self.showMenu = false
                }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                        .foregroundStyle(navigation == .search ? theme.tintColor : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .tint(self.theme.tintColor)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .blendMode(.colorDodge)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
}
