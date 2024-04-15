//
//  SettingsView.swift
//  Read
//
//  Created by Mirna Olvera on 2/26/24.
//

import Combine
import SwiftUI

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

struct SettingsView: View {
    @Environment(AppTheme.self) var theme
    @Environment(Navigator.self) var navigator
    @Environment(\.presentationMode) var presentationMode

    @StateObject var colorPickerObserver = ColorPickerObserver(defaultColor: .accent)

    var body: some View {
        VStack {
            List {
                Section {
                    HStack {
                        ColorPicker(
                            "Set the theme color",
                            selection: $colorPickerObserver.selectedColor,
                            supportsOpacity: false
                        )
                    }

                    Button {
                        navigator.navigate(
                            to: .sourceSettings
                        )
                    } label: {
                        Text("sources")
                    }
                    .tint(.primary)

                } header: {
                    Text("Settings")
                }

                Section {
                    Button {
                        theme.restoreToDefaults()
                        colorPickerObserver.selectedColor = theme.tintColor
                    } label: {
                        Text("Reset theme")
                    }
                    .tint(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Advanced")
                }
            }
            .navigationTitle("Settings")
            .navigationBarBackButtonHidden(true)
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

#Preview {
    SettingsView()
}
