//
//  ThemeColorPicker.swift
//  Read
//
//  Created by Mirna Olvera on 4/18/24.
//

import Combine
import SwiftUI

struct ThemeColorPicker: View {
    @Environment(AppTheme.self) var theme
    @StateObject var colorPickerObserver = ColorPickerObserver(defaultColor: .accent)

    var body: some View {
        HStack {
            ColorPicker(
                "Set the theme color",
                selection: $colorPickerObserver.selectedColor,
                supportsOpacity: false
            )
        }
        .onAppear {
            colorPickerObserver.selectedColor = theme.tintColor
            colorPickerObserver.debouncedColor = theme.tintColor
        }
        .onChange(of: colorPickerObserver.debouncedColor) { _, newValue in
            theme.tintColor = newValue
        }
    }
}

extension ThemeColorPicker {
    class ColorPickerObserver: ObservableObject {
        @Published var selectedColor: Color
        @Published var debouncedColor: Color

        private var subscriptions = Set<AnyCancellable>()

        init(defaultColor: Color) {
            self.selectedColor = defaultColor
            self.debouncedColor = defaultColor

            $selectedColor
                .debounce(for: .seconds(0.8), scheduler: DispatchQueue.main)
                .sink { [weak self] color in
                    self?.debouncedColor = color
                }
                .store(in: &subscriptions)
        }
    }
}

#Preview {
    ThemeColorPicker()
}
