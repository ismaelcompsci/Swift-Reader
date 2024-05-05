//
//  UISection.swift
//  Read
//
//  Created by Mirna Olvera on 4/30/24.
//

import Foundation
import JavaScriptCore
import SwiftUI

@objc class UISection: AnyUI {
    struct SRJSection: View {
        @ObservedObject var props: AnyUIProps

        var body: some View {
            let title = self.props.getString(name: "title")

            Section(title) {
                ForEach(self.props.children, id: \.id) { child in
                    child.render()
                }
            }
        }
    }

    override func render() -> AnyView {
        return AnyView(SRJSection(props: props))
    }
}
