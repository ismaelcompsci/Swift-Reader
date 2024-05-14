//
//  Reader+Overlay.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

struct ReaderOverlay: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme

    var title: String
    var currentLabel: String

    @Binding var showOverlay: Bool

    var settingsButtonPressed: (() -> Void)?
    var tocButtonPressed: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: Header

            if showOverlay {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .lineLimit(1)

                        Text(currentLabel)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    // MARK: Exit Button

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(theme.tintColor)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: 58)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            }

            Spacer()

            // MARK: Footer

            HStack(spacing: 12) {
                Spacer()

                // MARK: Contents Button

                if showOverlay {
                    Button {
                        tocButtonPressed?()
                    }
                    label: {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(theme.tintColor)
                            .font(.system(size: 22))
                            .frame(width: 48, height: 48)
                    }
                    .frame(width: 48, height: 48)
                    .background(.black)
                    .clipShape(.circle)

                    // MARK: Settings Button

                    Button {
                        settingsButtonPressed?()
                    }
                    label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.tintColor)
                            .font(.system(size: 22))
                            .frame(width: 48, height: 48)
                    }
                    .padding()
                    .frame(width: 48, height: 48)
                    .background(.black)
                    .clipShape(.circle)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: 58)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    VStack {
        ReaderOverlay(title: "TITLE", currentLabel: "", showOverlay: .constant(true))
            .environment(AppTheme.shared)
            .preferredColorScheme(.dark)
    }
}
