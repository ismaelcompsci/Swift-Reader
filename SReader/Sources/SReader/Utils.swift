//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/20/24.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

public func getRGBFromHex(hex: String) -> [String: Double] {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
        (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
        (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
        (a, r, g, b) = (1, 1, 1, 0)
    }

    return [
        "red": Double(r) / 255,
        "green": Double(g) / 255,
        "blue": Double(b) / 255,
        "opacity": Double(a) / 255
    ]
}

public enum SReaderFileTypes: String, CaseIterable {
    case EPUB = "epub"
//    case CBZ = "cbz" // disabled for now
    case FB2 = "fb2"
    case FBZ = "fbz"
    case MOBI = "mobi"
    case PDF = "pdf"
    case AZW3 = "azw3"
}

public let mobiFileType: UTType = .init(filenameExtension: "mobi") ?? .epub
public let azw3FileType: UTType = .init(filenameExtension: "azw3") ?? .epub
public let fb2FileType: UTType = .init(filenameExtension: "fb2") ?? .epub
public let fbzFileType: UTType = .init(filenameExtension: "fbz") ?? .epub
public let cbzFileType: UTType = .init(filenameExtension: "cbz") ?? .epub

public let fileTypes = [
    mobiFileType,
    azw3FileType,
    fb2FileType,
    fbzFileType,
    cbzFileType,
    .epub,
    .pdf
]

public func makeJSON(_ object: [String: Any]) -> [String: Any] {
    object.filter { _, value in
        !(value is NSNull)
    }
}

public func encodeIfNotNil(_ value: Any?) -> Any {
    value ?? NSNull()
}

public func serializeJSONString(_ object: Any) -> String? {
    guard
        let data = try? JSONSerialization.data(withJSONObject: object, options: .sortedKeys),
        let string = String(data: data, encoding: .utf8)
    else {
        return nil
    }

    // Unescapes slashes
    return string.replacingOccurrences(of: "\\/", with: "/")
}

public func encodeIfNotEmpty<T: Collection>(_ collection: T?) -> Any {
    guard let collection = collection else {
        return NSNull()
    }
    return collection.isEmpty ? NSNull() : collection
}

extension UIColor {
    // MARK: - Initialization

    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt32 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt32(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - Computed Properties

    var toHex: String? {
        return toHex()
    }

    // MARK: - From UIColor to String

    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
