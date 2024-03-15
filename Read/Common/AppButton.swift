//
//  AppButton.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import SwiftUI

/// TODO: can switch to a view modifer
/// aka ButtonStyle

struct AppButton: View {
    @EnvironmentObject var appColor: AppColor

    var systemName: String?
    var text: String?

    var onPress: (() -> Void)?

    init(systemName: String? = nil, text: String? = nil, onPress: (() -> Void)? = nil) {
        self.systemName = systemName
        self.text = text
        self.onPress = onPress
    }

    var body: some View {
        Button {
            onPress?()
        } label: {
            HStack {
                if let systemName {
                    Image(systemName: systemName)
                }
                if let text {
                    Text(text)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(appColor.accent)
            .clipShape(.capsule)
        }
    }
}

#Preview {
    AppButton(systemName: "book", text: "Open")
}
