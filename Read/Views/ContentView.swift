//
//  ContentView.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appColor: AppColor

    @State var showMenu = false
    @State var navigateSettings = false

    var body: some View {
        NavigationStack {
            VStack {
                HomeView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            self.showMenu = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(self.appColor.accent)
                    }
                }
            }
            .navigationDestination(isPresented: self.$navigateSettings, destination: {
                SettingsView()
            })
        }
        .sideMenu(isShowing: self.$showMenu) {
            self.sideMenu
        }
    }

    var sideMenu: some View {
        VStack(alignment: .leading) {
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
                    self.showMenu = false
                    self.navigateSettings = true
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .tint(self.appColor.accent)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.font, Font.custom("Poppins-Regular", size: 16))
        .environmentObject(AppColor())
        .environmentObject(EditViewModel())
}
