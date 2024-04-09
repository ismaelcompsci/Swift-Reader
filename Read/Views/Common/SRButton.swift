//
//  SRButton.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import SwiftUI

struct SRButton: View {
    @Environment(AppTheme.self) var theme

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
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 12)
            .foregroundStyle(.white)
            .background(theme.tintColor)
            .clipShape(.rect(cornerRadius: 10))
        }
    }
}

#Preview {
    SRButton(systemName: "book", text: "Open")
        .preferredColorScheme(.dark)
}
