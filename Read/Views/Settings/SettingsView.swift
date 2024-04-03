//
//  SettingsView.swift
//  Read
//
//  Created by Mirna Olvera on 2/26/24.
//

import SwiftUI

// only used for debounce.
class SettingsViewModel: ObservableObject {
    @Published var selectedColor: Color = .clear

    init(selectedColor: Color) {
        self.selectedColor = selectedColor
    }
}

struct SettingsView: View {
    @EnvironmentObject var appColor: AppColor
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedColor: Color = .accent
    @StateObject private var viewModel = SettingsViewModel(selectedColor: .accent)

    var body: some View {
        VStack {
            List {
                Section {
                    HStack {
                        ColorPicker("Set the theme color", selection: $viewModel.selectedColor, supportsOpacity: false)
                    }

                    NavigationLink {
                        SettingsSourcesView()
                    } label: {
                        Text("Extensions")
                    }
                    .tint(appColor.accent)

                    Button {
                        appColor.accent = .accent
                        selectedColor = .accent
                    } label: {
                        Text("Reset theme")
                    }
                    .tint(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)

                } header: {
                    Text("Settings")
                }
            }
            .navigationTitle("Settings")
            .navigationBarBackButtonHidden(true)
        }
        .onAppear {
            viewModel.selectedColor = appColor.accent
        }
        .onReceive(
            viewModel.$selectedColor.debounce(for: 1, scheduler: RunLoop.main)
        ) { color in
            appColor.accent = color
        }
    }
}

#Preview {
    SettingsView()
}
