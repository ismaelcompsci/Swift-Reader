//
//  UIMultilineLabel.swift
//  Read
//
//  Created by Mirna Olvera on 5/5/24.
//

import Foundation
import JavaScriptCore
import SwiftUI

class UIMultilineLabel: AnyUI {
    struct _UIMultilineLabel: View {
        @ObservedObject var props: AnyUIProps

        var body: some View {
            let label = self.props.getString(name: "label")
            let value = self.props.getString(name: "value")

            VStack(alignment: .leading) {
                Text(label)
                    .fontWeight(.semibold)

                Text(value)
            }
        }
    }

    override func render() -> AnyView {
        return AnyView(_UIMultilineLabel(props: props))
    }
}
