//
//  AnyUI.swift
//  Read
//
//  Created by Mirna Olvera on 5/1/24.
//

import Foundation
import JavaScriptCore
import SwiftUI

@objc protocol AnyUIJSExport: JSExport {
    var id: String { get }
}

class AnyUI: NSObject, AnyUIJSExport {
    var id: String

    let props = AnyUIProps()

    func render() -> AnyView {
        return AnyView(EmptyView())
    }

    @objc public func setProp(_ name: String, _ value: JSValue?) {
        assert(name != "children", "Err: User `removeChild` or `insertBefore` to update children!")
        props.values[name] = value

        updateCount()
    }

    func updateCount() {
        props.updateCount = (props.updateCount + 1) % 10
    }

    func setChildren(_ newChildren: [AnyUI]) {
        props.children = newChildren

        updateCount()
    }

    init(id: String) {
        self.id = id
    }
}

class AnyUIProps: ObservableObject {
    @Published var values: [String: JSValue?] = [:]
    @Published var children: [AnyUI] = []

    @Published var updateCount = 0

    func getString(name: String, default: String = "") -> String {
        if let prop = (values[name] ?? nil) {
            return prop.toString()
        }
        return `default`
    }

    func getChildren() -> [AnyUI] {
        children
    }

    func getPropAsJSValue(name: String) -> JSValue? {
        values[name] ?? nil
    }
}
