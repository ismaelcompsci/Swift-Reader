//
//  SettingsView.swift
//  Read
//
//  Created by Mirna Olvera on 2/26/24.
//

import SwiftUI

// only used for debounce. okay?
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
                HStack {
                    ColorPicker("Set the theme color", selection: $viewModel.selectedColor, supportsOpacity: false)
                }
            }
            .navigationTitle("Settings")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: { presentationMode.wrappedValue.dismiss() }, label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(appColor.accent)

                        Text("Home")
                            .foregroundColor(appColor.accent)
                    }
                })
            )
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
