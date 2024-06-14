//
//  UIInputField.swift
//  Read
//
//  Created by Mirna Olvera on 5/2/24.
//

import Foundation
import SwiftUI

class UIInputField: AnyUI {
    struct _UIInputField: View {
        @ObservedObject var props: AnyUIProps
        @State var input: UIInputFieldValue

        init(props: AnyUIProps) {
            self._props = ObservedObject(wrappedValue: props)
            self._input = State(
                initialValue: UIInputFieldValue(
                    id: props.getString(name: "id"),
                    value: props.getString(name: "value")
                )
            )
        }

        var body: some View {
            let label = self.props.getString(name: "label")

            TextField(label, text: self.$input.value)
                .preference(key: UIInputFieldKey.self, value: self.input)
        }
    }

    override func render() -> AnyView {
        return AnyView(_UIInputField(props: self.props))
    }
}

struct UIInputFieldValue: Equatable {
    var id: String
    var value: String

    static func ==(lhs: UIInputFieldValue, rhs: UIInputFieldValue) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value
    }
}

struct UIInputFieldKey: PreferenceKey {
    static let defaultValue: UIInputFieldValue? = nil

    static func reduce(value: inout UIInputFieldValue?, nextValue: () -> UIInputFieldValue?) {
        value = nextValue()
    }
}
