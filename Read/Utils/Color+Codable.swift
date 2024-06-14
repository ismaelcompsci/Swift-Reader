//
//  Color+Codable.swift
//  Read
//
//  Created by Mirna Olvera on 3/13/24.
//

import Foundation
import SwiftUI
import UIKit

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: Int) {
        let red = Double((rawValue & 0xFF0000) >> 16) / 0xFF
        let green = Double((rawValue & 0x00FF00) >> 8) / 0xFF
        let blue = Double(rawValue & 0x0000FF) / 0xFF
        self = Color(red: red, green: green, blue: blue)
    }

    public var rawValue: Int {
        guard let coreImageColor else {
            return 0
        }
        let red = Int(coreImageColor.red * 255 + 0.5)
        let green = Int(coreImageColor.green * 255 + 0.5)
        let blue = Int(coreImageColor.blue * 255 + 0.5)
        return (red << 16) | (green << 8) | blue
    }

    private var coreImageColor: CIColor? {
        CIColor(color: .init(self))
    }
}
