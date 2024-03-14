//
//  ReadApp.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import SwiftUI

@main
struct ReadApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.font, Font.custom("Poppins-Regular", size: 16))
                .environmentObject(AppColor())
                .environmentObject(OrientationInfo())
                .environmentObject(EditViewModel())
                .preferredColorScheme(.dark)
        }
    }
}

extension Color {
    static let accent = Color("Main")
    static let accentBackground = Color("Main").opacity(0.12)

    static let backgroundSecondary = Color(red: 0.10, green: 0.10, blue: 0.10)
}
