//
//  XButton.swift
//  Read
//
//  Created by Mirna Olvera on 3/15/24.
//

import SwiftUI

struct SRXButton: View {
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            action?()
        }, label: {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                )
        })
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Close"))
    }
}

#Preview {
    SRXButton()
        .preferredColorScheme(.dark)
}
