//
//  Color+Codable.swift
//  Read
//
//  Created by Mirna Olvera on 3/13/24.
//

import Foundation
import SwiftUI
import UIKit

extension Color: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .accent
            return
        }

        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) ?? UIColor(Color.accent)
            self = Color(color)
        } catch {
            self = .accent
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false) as Data
            return data.base64EncodedString()

        } catch {
            return ""
        }
    }
}
