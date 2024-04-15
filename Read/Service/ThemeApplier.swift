//
//  ThemeApplier.swift
//  Read
//
//  Created by Mirna Olvera on 4/15/24.
//

import SwiftUI
import UIKit

// https://github.com/Dimillian/IceCubesApp/blob/7d47834903133c96d4fae941b4504adb13743a9b/Packages/DesignSystem/Sources/DesignSystem/ThemeApplier.swift#L8
struct ThemeApplier: ViewModifier {
    var theme: AppTheme

    func body(content: Content) -> some View {
        content
            .tint(theme.tintColor)
            .onAppear {
                setWindowTint(theme.tintColor)
                setBarColor(theme.tintColor)
            }
            .onChange(of: theme.tintColor) { _, newValue in
                setWindowTint(newValue)
                setBarColor(newValue)
            }
    }

    private func setWindowTint(_ color: Color) {
        for window in allWindows() {
            window.tintColor = UIColor(color)
        }
    }

    private func setBarColor(_ color: Color) {
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().barTintColor = UIColor(color)
    }

    private func allWindows() -> [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }
}

public extension View {
    func applyTheme(_ theme: AppTheme) -> some View {
        modifier(ThemeApplier(theme: theme))
    }
}
