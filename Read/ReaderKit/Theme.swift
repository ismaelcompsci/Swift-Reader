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

protocol ThemeProtocol {
    // MARK: Layout

    var gap: Double { get set }
    var maxInlineSize: Int { get set }
    var maxBlockSize: Int { get set }
    var maxColumnCount: Int { get set }
    var flow: Bool { get set }
    var animated: Bool { get set }
    var margin: Int { get set }

    // MARK: Style

    var lineHeight: Double { get set }
    var justify: Bool { get set }
    var hyphenate: Bool { get set }
    var fontSize: Int { get set }

    // MARK: Book Theme

    var bg: ThemeBackground { get set }
    var fg: ThemeForeground { get set }

    func save()

    // init get saved data
}

struct Theme: ThemeProtocol, Codable {
    // MARK: Layout

    static let saveKey = "ReaderTheme"

    var gap = 0.06
    var maxInlineSize = 1080
    var maxBlockSize = 1440
    var maxColumnCount = 1
    var flow = false
    var animated = true
    var margin = 24

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
        let newGap = gap + 0.01
        gap = min(100, newGap)
    }

    mutating func decreaseGap() {
        let newGap = gap - 0.01
        gap = max(0, newGap)
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

    mutating func increaseMargin() {
        let newMargin = margin + 2
        margin = min(200, newMargin)
    }

    mutating func decreaseMargin() {
        let newMargin = margin - 2
        margin = max(0, newMargin)
    }

    mutating func increaseLineHeight() {
        let new = lineHeight + 0.1

        lineHeight = min(7, new)
    }

    mutating func decreaseLineHeight() {
        let new = lineHeight - 0.1

        lineHeight = max(0.8, new)
    }

    init() {
        if let decodedData = UserDefaults.standard.data(forKey: Theme.saveKey) {
            if let theme = try? JSONDecoder().decode(Theme.self, from: decodedData) {
                self.gap = theme.gap
                self.animated = theme.animated
                self.maxInlineSize = theme.maxInlineSize
                self.maxBlockSize = theme.maxBlockSize
                self.maxColumnCount = theme.maxColumnCount
                self.margin = theme.margin
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
