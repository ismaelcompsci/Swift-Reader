//
//  Theme.swift
//  Read
//
//  Created by Mirna Olvera on 2/6/24.
//

import Foundation
import RealmSwift

enum ThemeBackground: String, Codable, CaseIterable, Identifiable {
    var id: Self {
        return self
    }

    case light = "#ffffff"
    case dark = "#09090b"
    case sepia = "#f1e8d0"

    func fromForeground(foreground: ThemeForeground) -> ThemeBackground {
        switch foreground {
        case .light:
            return .light
        case .dark:
            return .dark
        case .sepia:
            return .sepia
        }
    }

    func fromBackground(background: ThemeBackground) -> ThemeForeground {
        switch background {
        case .light:
            return .light
        case .dark:
            return .dark
        case .sepia:
            return .sepia
        }
    }
}

enum ThemeForeground: String, Codable, CaseIterable, Identifiable {
    var id: Self {
        return self
    }

    case light = "#000000"
    case dark = "#d2d2d2"
    case sepia = "#5b4636"

    func fromBackground(background: ThemeBackground) -> ThemeForeground {
        switch background {
        case .light:
            return .light
        case .dark:
            return .dark
        case .sepia:
            return .sepia
        }
    }

    func fromForeground(foreground: ThemeForeground) -> ThemeBackground {
        switch foreground {
        case .light:
            return .light
        case .dark:
            return .dark
        case .sepia:
            return .sepia
        }
    }
}

struct Theme: Codable {
    // MARK: Layout

    static let saveKey = "ReaderTheme"

    var gap = 0.06
    var maxInlineSize = 720
    var maxBlockSize = 1440
    var maxColumnCount = 1
    var flow = false

    // MARK: Style

    var lineHeight = 1.5
    var justify = true
    var hyphenate = true
    var fontSize = 100

    // MARK: Book Theme

    var bg: ThemeBackground = .dark
    var fg: ThemeForeground = .dark

    // TODO: SET MINIMUM AND MAXIMUM VALUES

    mutating func increaseFontSize() {
        fontSize += 2
    }

    mutating func decreaseFontSize() {
        fontSize -= 2
    }

    mutating func increaseGap() {
        gap += 0.01
    }

    mutating func decreaseGap() {
        gap -= 0.01
    }

    mutating func increaseBlockSize() {
        maxBlockSize += 50
    }

    mutating func decreaseBlockSize() {
        maxBlockSize -= 50
    }

    mutating func setMaxColumnCount(_ count: Int) {
        maxColumnCount = count
    }

    init() {
        if let decodedData = UserDefaults.standard.data(forKey: Theme.saveKey) {
            if let theme = try? JSONDecoder().decode(Theme.self, from: decodedData) {
                self.gap = theme.gap
                self.maxInlineSize = theme.maxInlineSize
                self.maxBlockSize = theme.maxBlockSize
                self.maxColumnCount = theme.maxColumnCount
                self.flow = theme.flow
                self.lineHeight = theme.lineHeight
                self.justify = theme.justify
                self.hyphenate = theme.hyphenate
                self.fontSize = theme.fontSize
                self.bg = theme.bg
                self.fg = theme.fg
            }
        }
    }

    func save() {
        if let encodedTheme = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encodedTheme, forKey: Theme.saveKey)
        }
    }
}
