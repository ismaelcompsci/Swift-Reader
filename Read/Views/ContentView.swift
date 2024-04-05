//
//  ContentView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appColor: AppColor

    @State var showMenu = false
    @State var navigation: SideMenuNavigation = .home

    enum SideMenuNavigation: String {
        case home = "Home"
        case settings = "Settings"
        case discover = "Discover"
        case search = "Search"
    }

    var body: some View {
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
                            .foregroundStyle(self.appColor.accent)
                    }
                }
            }
        }
        .sideMenu(isShowing: self.$showMenu) {
            self.sideMenu
        }
    }

    var sideMenu: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()

                XButton {
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
                        .foregroundStyle(navigation == .home ? appColor.accent : .white)
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
                        .foregroundStyle(navigation == .settings ? appColor.accent : .white)
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
                        .foregroundStyle(navigation == .discover ? appColor.accent : .white)
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
                        .foregroundStyle(navigation == .search ? appColor.accent : .white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .tint(self.appColor.accent)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundSecondary)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
        .environmentObject(AppColor())
        .environmentObject(EditViewModel())
}
