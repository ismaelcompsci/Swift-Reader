//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/20/24.
//

import UIKit

extension UIView {
    static func getAllSubviews<T: UIView>(from parenView: UIView) -> [T] {
        return parenView.subviews.flatMap { subView -> [T] in
            var result = self.getAllSubviews(from: subView) as [T]
            if let view = subView as? T { result.append(view) }
            return result
        }
    }

    func disableMenuInteractions() {
        let views = UIView.getAllSubviews(from: self)
        for view in views {
            for interaction in view.interactions where interaction is UIEditMenuInteraction {
                view.removeInteraction(interaction)
            }
        }
    }
}
