//
//  UINavigationButton.swift
//  Read
//
//  Created by Mirna Olvera on 5/2/24.
//

import Foundation
import JavaScriptCore
import SwiftUI

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

class UINavigationButton: AnyUI {
    struct _UINavigationButton: View {
        @ObservedObject var props: AnyUIProps

        var body: some View {
            VStack {
                let label = self.props.getString(name: "label")

                NavigationLink {
                    props.children[0].render()
                } label: {
                    Text(label)
                }
            }
        }
    }

    override func render() -> AnyView {
        return AnyView(_UINavigationButton(props: props))
    }
}
