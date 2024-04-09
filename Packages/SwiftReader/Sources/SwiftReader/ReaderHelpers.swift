//
//  Helpers.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import CoreGraphics
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

    return ["red": Double(r) / 255, "green": Double(g) / 255, "blue": Double(b) / 255, "opacity": Double(a) / 255]
}

extension UIView {
    class func getAllSubviews<T: UIView>(from parenView: UIView) -> [T] {
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

public enum SupportedFileTypes: String, CaseIterable {
    case EPUB = "epub"
    case CBZ = "cbz" // disabled for now
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

public let fileTypes = [mobiFileType, azw3FileType, fb2FileType, fbzFileType, cbzFileType, .epub, .pdf]

public let signatures: [String: String] = [
    "iVBORw0KGgo": ".png",
    "/9j/4": ".jpeg",
    "/9j/": ".jpg"
]

public func getImageType(base64: String) -> String? {
    for (sign, type) in signatures {
        if base64.hasPrefix(sign) {
            return type
        }
    }
    return nil
}

func pdfToImage(from url: URL, at page: Int) -> UIImage? {
    guard let document = CGPDFDocument(url as CFURL) else { return nil }

    guard let page = document.page(at: page) else { return nil }

    let pageRect = page.getBoxRect(.mediaBox)

    let cropRect = pageRect

    let renderer = UIGraphicsImageRenderer(size: cropRect.size)
    let img = renderer.image { ctx in
        // Set the background color.
        UIColor.white.set()
        ctx.fill(CGRect(x: 0, y: 0, width: cropRect.width, height: cropRect.height))

        // Translate the context so that we only draw the `cropRect`.
        ctx.cgContext.translateBy(x: -cropRect.origin.x, y: pageRect.size.height - cropRect.origin.y)

        // Flip the context vertically because the Core Graphics coordinate system starts from the bottom.
        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

        // Draw the PDF page.
        ctx.cgContext.drawPDFPage(page)
    }

    return img
}
