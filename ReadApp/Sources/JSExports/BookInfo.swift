//
//  BookInfo.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol BookInfoJSExport: JSExport {
    var title: String { get set }
    var author: String? { get set }
    var desc: String? { get set }
    var image: String? { get set }
    var tags: [String]? { get set }
    var downloadLinks: [DownloadInfo] { get set }

    // swiftlint:disable:next identifier_name function_parameter_count
    static func _createBookInfo(
        title: String,
        author: String?,
        desc: String?,
        image: String?,
        tags: [String]?,
        downloadLinks: [DownloadInfo]
    ) -> BookInfo
}

class BookInfo: NSObject, BookInfoJSExport {
    var title: String
    var author: String?
    var desc: String?
    var image: String?
    var tags: [String]?
    var downloadLinks: [DownloadInfo]

    init(
        title: String,
        author: String? = nil,
        desc: String? = nil,
        image: String? = nil,
        tags: [String]? = nil,
        downloadLinks: [DownloadInfo]
    ) {
        self.title = title
        self.author = author
        self.desc = desc
        self.image = image
        self.tags = tags
        self.downloadLinks = downloadLinks
    }

    // swiftlint:disable:next identifier_name function_parameter_count
    class func _createBookInfo(
        title: String,
        author: String?,
        desc: String?,
        image: String?,
        tags: [String]?,
        downloadLinks: [DownloadInfo]
    ) -> BookInfo {
        BookInfo(title: title, author: author, desc: desc, image: image, tags: tags, downloadLinks: downloadLinks)
    }
}
