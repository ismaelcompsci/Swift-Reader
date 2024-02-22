//
//  Font+Extension.swift
//  Read
//
//  Created by Mirna Olvera on 2/21/24.
//

import SwiftUI

extension Font {
    static func setCustom(fontStyle: Font.TextStyle, fontWeight: Weight = .regular) -> Font {
        if #available(iOS 16.0, *) {
            return Font.system(size: fontStyle.size, weight: fontWeight, design: .default)
        } else {
            // Fallback on earlier versions
            return Font.system(size: fontStyle.size, design: .default).weight(fontWeight)
        }
    }
}

extension UIFont {
    static func setCustom(fontStyle: Font.TextStyle, fontWeight: CustomFont) -> UIFont? {
        return UIFont(name: fontWeight.rawValue, size: fontStyle.size)
    }

    static func setSystem(fontStyle: Font.TextStyle, fontWeight: Weight) -> UIFont? {
        return systemFont(ofSize: fontStyle.size, weight: fontWeight)
    }
}

extension Font.TextStyle {
    var size: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 18
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default:
            return 8
        }
    }
}

enum CustomFont: String {
    case regular = "Poppins-Regular"
    case semibold = "Poppins-SemiBold"
    case medium = "Poppins-Medium"
    case bold = "Poppins-Bold"
    case extrabold = "Poppins-ExtraBold"
}
