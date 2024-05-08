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

                    goToSourcesButton

                    HStack {
                        Text("Home Grid columns")

                        Spacer()

                        Stepper("\(preferences.numberOfColumns)") {
                            preferences.numberOfColumns += 1
                        } onDecrement: {
                            let newValue = preferences.numberOfColumns - 1

                            preferences.numberOfColumns = max(1, newValue)
                        }
                    }

                } header: {
                    Text("Settings")
                }
                .tint(.primary)

                Section {
                    goToDownloadManagerButton

                    openDownloadFolderButton

                    clearDownloadFolderButton

                } header: {
                    Text("Storage")
                }
                .tint(.primary)

                Section {
                    resetThemeButton

                    Button {
                        theme.restoreToDefaults()
                        preferences.reset()
                    } label: {
                        Text("Reset All")
                            .foregroundStyle(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                } header: {
                    Text("Advanced")
                }
            }
        }
        .navigationBarTitle("Settings", displayMode: .large)
        .onAppear {
            downloadFolderSize = BookDownloader.getDownloadFolderSize()
        }
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

    var goToSourcesButton: some View {
        Button {
            navigator.navigate(
                to: .sourceSettings
            )
        } label: {
            HStack {
                Text("Sources")

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
    }

    var goToDownloadManagerButton: some View {
        Button {
            navigator.navigate(to: .downloadManager)
        } label: {
            HStack {
                Text("Download Manager")

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
    }

    @ViewBuilder
    var openDownloadFolderButton: some View {
        Button {
            let path = DownloadManager.downloadsPath
            let sharedurl = path.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
            let furl = URL(string: sharedurl)!
            if UIApplication.shared.canOpenURL(furl) {
                UIApplication.shared.open(furl, options: [:])
            }
        } label: {
            HStack {
                Text("Open downloads folder")
                Spacer()
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    var clearDownloadFolderButton: some View {
        let formattedString = ByteCountFormatter.string(fromByteCount: Int64(downloadFolderSize), countStyle: .file)

        Button {
            BookDownloader.clearDownloadFolder()
            downloadFolderSize = BookDownloader.getDownloadFolderSize()
        } label: {
            HStack {
                Text("Clear download folder")
                Spacer()
                Text("\(formattedString)")
            }
            .foregroundStyle(.red)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppTheme.shared)
        .environment(Navigator())
}
