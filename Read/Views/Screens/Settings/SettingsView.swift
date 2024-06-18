//
//  SettingsView.swift
//  Read
//
//  Created by Mirna Olvera on 2/26/24.
//

import DownloadManager
import SwiftUI

struct SettingsView: View {
    @Environment(AppTheme.self) var theme
    @Environment(Navigator.self) var navigator
    @Environment(UserPreferences.self) var preferences
    @Environment(\.presentationMode) var presentationMode

    @State private var downloadFolderSize: UInt64 = 0

    var body: some View {
        VStack {
            List {
                Section {
                    ThemeColorPicker()

                } header: {
                    Text("Settings")
                }
                .tint(.primary)

                Section {
                    resetThemeButton

                    resetAllButton

                } header: {
                    Text("Advanced")
                }
            }
        }
        .navigationBarTitle("Settings", displayMode: .large)
    }

    var resetAllButton: some View {
        Button {
            theme.restoreToDefaults()
            preferences.reset()
        } label: {
            Text("Reset All")
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var resetThemeButton: some View {
        Button {
            theme.restoreToDefaults()
        } label: {
            Text("Reset theme")
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SettingsView()
        .environment(AppTheme.shared)
        .environment(Navigator())
}
