//
//  FormInput.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import SwiftUI

struct FormInput: View {
    @FocusState private var focus: Bool

    @Binding var text: String

    let inputTitle: String
    let axis: Axis

    init(text: Binding<String>, inputTitle: String, axis: Axis = .horizontal) {
        self._text = text
        self.inputTitle = inputTitle
        self.axis = axis
    }

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading, isVertical: axis == .vertical) {
            Text(inputTitle)
                .foregroundStyle(.gray)

            TextField("", text: $text, axis: axis)
                .padding(.leading, 10)
                .focused($focus)
                .submitLabel(.done)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .clipShape(.rect(cornerRadius: 12))
        .onTapGesture {
            focus.toggle()
        }
    }
}

#Preview {
    FormInput(text: .constant("HELLO"), inputTitle: "Test", axis: .vertical)
}
