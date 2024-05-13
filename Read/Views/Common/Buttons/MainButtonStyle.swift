//
//  SRButton.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import SwiftUI

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MainButton(configuration: configuration)
    }
}

extension ButtonStyle where Self == MainButtonStyle {
    static var main: MainButtonStyle {
        MainButtonStyle()
    }
}

struct MainButton: View {
    @Environment(AppTheme.self) var theme

    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34)
            .padding(.horizontal, 12)
            .foregroundStyle(.white)
            .background(theme.tintColor)
            .clipShape(.rect(cornerRadius: 10))
    }
}

#Preview {
    VStack {
        Button {} label: {
            Image(systemName: "book")
        }
        .buttonStyle(.main)
    }
    .padding()
    .environment(AppTheme.shared)
}
