//
//  UIButton.swift
//  Read
//
//  Created by Mirna Olvera on 5/1/24.
//

import Foundation
import JavaScriptCore
import SwiftUI

class UIButton: AnyUI {
    struct SRJButton: View {
        @ObservedObject var props: AnyUIProps

        func onPress() {
            if let onTap = props.getPropAsJSValue(name: "onTap") {
                onTap.call(withArguments: [])
            }
        }

        var body: some View {
            let label = self.props.getString(name: "label")

            Button(label) {
                self.onPress()
            }
        }
    }

    override func render() -> AnyView {
        return AnyView(SRJButton(props: props))
    }
}
