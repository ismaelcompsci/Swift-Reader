//
//  Theme.swift
//
//
//  Created by Mirna Olvera on 5/18/24.
//

import Foundation

public struct BookTheme: Codable {
    // MARK: Layout

    public static let saveKey = "ReaderTheme"

    public var gap = 0.06
    public var maxInlineSize = 1080
    public var maxBlockSize = 1440
    public var maxColumnCount = 1
    public var flow = false
    public var animated = true
    public var margin = 24

    // MARK: Style

    public var lineHeight = 1.5
    public var justify = true
    public var hyphenate = true
    public var fontSize = 100

    // MARK: Book Theme

    public var bg: ThemeBackground = .light
    public var fg: ThemeForeground = .light

    // TODO: SET MINIMUM AND MAXIMUM VALUES

    public mutating func increaseFontSize() {
        fontSize += 2
    }

    public mutating func decreaseFontSize() {
        fontSize -= 2
    }

    public mutating func increaseGap() {
        let newGap = gap + 0.01
        gap = min(100, newGap)
    }

    public mutating func decreaseGap() {
        let newGap = gap - 0.01
        gap = max(0, newGap)
    }

    public mutating func increaseBlockSize() {
        maxBlockSize += 50
    }

    public mutating func decreaseBlockSize() {
        maxBlockSize -= 50
    }

    public mutating func setMaxColumnCount(_ count: Int) {
        maxColumnCount = count
    }

    public mutating func increaseMargin() {
        let newMargin = margin + 2
        margin = min(200, newMargin)
    }

    public mutating func decreaseMargin() {
        let newMargin = margin - 2
        margin = max(0, newMargin)
    }

    public mutating func increaseLineHeight() {
        let new = lineHeight + 0.1

        lineHeight = min(7, new)
    }

    public mutating func decreaseLineHeight() {
        let new = lineHeight - 0.1

        lineHeight = max(0.8, new)
    }

    public init() {
        if let decodedData = UserDefaults.standard.data(forKey: BookTheme.saveKey) {
            if let theme = try? JSONDecoder().decode(BookTheme.self, from: decodedData) {
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
            UserDefaults.standard.set(encodedTheme, forKey: BookTheme.saveKey)
        }
    }
}

public enum ThemeBackground: String, Codable, CaseIterable, Identifiable {
    public var id: Self {
        return self
    }

    case light = "#ffffff"
    case dark = "#000000"
    case sepia = "#f1e8d0"

    public func fromForeground(foreground: ThemeForeground) -> ThemeBackground {
        switch foreground {
        case .light:
            return .light
        case .dark:
            return .dark
        case .sepia:
            return .sepia
        }
    }

    public func fromBackground(background: ThemeBackground) -> ThemeForeground {
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

public enum ThemeForeground: String, Codable, CaseIterable, Identifiable {
    public var id: Self {
        return self
    }

    case light = "#000000"
    case dark = "#d2d2d2"
    case sepia = "#5b4636"

    public func fromBackground(background: ThemeBackground) -> ThemeForeground {
        switch background {
        case .light:
            return .light
        case .dark:
            return .dark
        case .sepia:
            return .sepia
        }
    }

    public func fromForeground(foreground: ThemeForeground) -> ThemeBackground {
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
