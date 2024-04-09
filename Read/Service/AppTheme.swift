//
//  AppColor.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import Foundation
import SwiftUI

@Observable
public class AppTheme {
    public class ThemeStorage {
        enum ThemeKey: String {
            case tintColor
        }

        @AppStorage(ThemeKey.tintColor.rawValue) public var tintColor: Color = .accent
    }

    public static let shared = AppTheme()

    let themeStorage = ThemeStorage()

    public var tintColor: Color {
        didSet {
            themeStorage.tintColor = tintColor
        }
    }

    private init() {
        tintColor = themeStorage.tintColor
    }

    public func restoreToDefaults() {
        tintColor = .accent
    }
}

extension Color {
    static let accent = Color("Main")
    static let accentBackground = Color("Main").opacity(0.12)

    static let backgroundSecondary = Color(red: 0.10, green: 0.10, blue: 0.10)
}
