//
//  SheetHeader.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import SwiftUI

struct SheetHeader: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appColor: AppColor

    let title: String

    var body: some View {
        HStack {
            // MARK: TITLE

            Text(title)
                .font(.title.weight(.semibold))

            Spacer()

            // MARK: DISMISS

            Button {
                dismiss()
            }
            label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24))
                    .foregroundStyle(appColor.accent.opacity(0.7))
            }
        }
    }
}

#Preview {
    SheetHeader(title: "Edit a book")
}
