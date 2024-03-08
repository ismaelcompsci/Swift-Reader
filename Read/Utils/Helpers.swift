//
//  Helpers.swift
//  Read
//
//  Created by Mirna Olvera on 1/30/24.
//

import CoreGraphics
import Foundation
import SwiftUI

let signatures: [String: String] = [
    "iVBORw0KGgo": ".png",
    "/9j/4": ".jpeg",
    "/9j/": ".jpg"
]

func getImageType(base64: String) -> String? {
    for (sign, type) in signatures {
        if base64.hasPrefix(sign) {
            return type
        }
    }
    return nil
}

func getEmbeddedImages(ofPDFAt url: URL, pageIndex: Int) -> [UIImage]? {
    guard let document = CGPDFDocument(url as CFURL) else {
        print("Couldn't open PDF.")
        return nil
    }
    // `page(at:)` uses pages numbered starting at 1.
    let page = pageIndex + 1
    guard let pdfPage = document.page(at: page), let dictionary = pdfPage.dictionary else {
        print("Couldn't open page.")
        return nil
    }
    var res: CGPDFDictionaryRef?
    guard CGPDFDictionaryGetDictionary(dictionary, "Resources", &res), let resources = res else {
        print("Couldn't get Resources.")
        return nil
    }
    var xObj: CGPDFDictionaryRef?
    guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObj), let xObject = xObj else {
        print("Couldn't load page XObject.")
        return nil
    }

    var imageKeys = [String]()
    CGPDFDictionaryApplyBlock(xObject, { key, object, _ in
        var stream: CGPDFStreamRef?
        guard CGPDFObjectGetValue(object, .stream, &stream),
              let objectStream = stream,
              let streamDictionary = CGPDFStreamGetDictionary(objectStream) else { return true }
        var subtype: UnsafePointer<Int8>?
        guard CGPDFDictionaryGetName(streamDictionary, "Subtype", &subtype), let subtypeName = subtype else { return true }
        if String(cString: subtypeName) == "Image" {
            imageKeys.append(String(cString: key))
        }
        return true
    }, nil)

    let allPageImages = imageKeys.compactMap { imageKey -> UIImage? in
        print(imageKey)
        var stream: CGPDFStreamRef?
        guard CGPDFDictionaryGetStream(xObject, imageKey, &stream), let imageStream = stream else {
            print("Couldn't get image stream.")
            return nil
        }
        var format: CGPDFDataFormat = .raw
        guard let data = CGPDFStreamCopyData(imageStream, &format) else {
            print("Couldn't convert image stream to data.")
            return nil
        }
        guard let image = UIImage(data: data as Data) else {
            print("Couldn't convert image data to image.")
            return nil
        }
        return image
    }

    return allPageImages
}

func getPDFCover(ofPDFAt: URL) -> UIImage? {
    if let images = getEmbeddedImages(ofPDFAt: ofPDFAt, pageIndex: 0) {
        var image: UIImage?

        for pdfImage in images {
            if pdfImage as UIImage? != nil {
                image = pdfImage
                break
            }
        }

        return image
    }
    return nil
}

func getBookCover(path imagePath: String?) -> UIImage? {
    if let imgPath = imagePath {
        let documentsPath = URL.documentsDirectory
        let fullImagePath = documentsPath.appending(path: imgPath)

        do {
            let data = try Data(contentsOf: fullImagePath)

            return UIImage(data: data)

        } catch {
            print("Error getting Book cover: \(error.localizedDescription)")
        }

        if let image = UIImage(contentsOfFile: fullImagePath.absoluteString) {
            return image
        }

        return /* UIImage(named: "default") */ nil
    } else {
//        return UIImage(named: "default")
        return nil
    }
}

func rgbaToInt(r: Int, g: Int, b: Int, a: Int) -> Int {
    return (r << 24) | (g << 16) | (b << 8) | a
}

func getRGBA(from convertedValue: Int) -> (r: Int, g: Int, b: Int, a: Int) {
    let r = (convertedValue >> 24) & 0xFF
    let g = (convertedValue >> 16) & 0xFF
    let b = (convertedValue >> 8) & 0xFF
    let a = convertedValue & 0xFF
    return (r, g, b, a)
}
