//
//  UIForm.swift
//  Read
//
//  Created by Mirna Olvera on 5/2/24.
//

import Foundation
import JavaScriptCore
import SwiftUI

class UIForm: AnyUI {
    struct _UIForm: View {
        @ObservedObject var props: AnyUIProps
        @State var childTextFieldValues: [String: String] = [:]

        var body: some View {
            let sections = self.props.getChildren()

            Form {
                ForEach(sections, id: \.id) { section in
                    section.render()
                }
                .onPreferenceChange(UIInputFieldKey.self) { item in
                    guard let item = item else { return }
                    self.childTextFieldValues[item.id] = item.value
                }
            }
            .onDisappear {
                let onSubmit = self.props.getPropAsJSValue(name: "onSubmit")

                onSubmit?.call(withArguments: [self.childTextFieldValues])
            }
        }
    }

    override func render() -> AnyView {
        return AnyView(_UIForm(props: self.props))
    }
}
