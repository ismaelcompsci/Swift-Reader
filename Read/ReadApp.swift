//
//  ReadApp.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SwiftUI

class AppColor: ObservableObject {
    @Published var accent: Color = .accent
}

@main
struct ReadApp: App {
    @ObservedObject var appColor = AppColor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.font, Font.custom("Poppins-Regular", size: 16))
                .environmentObject(AppColor())
                .tint(appColor.accent)
                .accentColor(appColor.accent)
                .preferredColorScheme(.dark)
                .environmentObject(OrientationInfo())
        }
    }
}
