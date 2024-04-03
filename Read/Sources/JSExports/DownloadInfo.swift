//
//  DownloadInfo.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

@objc protocol DownloadInfoJSExport: JSExport {
    var link: String { get set }
    var filetype: String { get set }

    // swiftlint:disable:next identifier_name
    static func _create(link: String, filetype: String) -> DownloadInfo
}

@objc class DownloadInfo: NSObject, DownloadInfoJSExport {
    var link: String
    var filetype: String

    init(link: String, filetype: String) {
        self.link = link
        self.filetype = filetype
    }

    // swiftlint:disable:next identifier_name
    class func _create(link: String, filetype: String) -> DownloadInfo {
        DownloadInfo(link: link, filetype: filetype)
    }
}
