//
//  UILink.swift
//  Read
//
//  Created by Mirna Olvera on 5/10/24.
//

import Foundation
import SwiftUI

class UILink: AnyUI {
    struct _UILink: View {
        @ObservedObject var props: AnyUIProps

        var body: some View {
            let value = self.props.getString(name: "value")
            let label = self.props.getString(name: "label")
            let url = URL(string: value)

            if let url = url {
                Link(destination: url) {
                    Label(label, systemImage: "globe")
                }
            }
        }
    }

    override func render() -> AnyView {
        return AnyView(_UILink(props: self.props))
    }
}
