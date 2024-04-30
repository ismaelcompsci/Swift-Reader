//
//  App.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore
import OSLog

@objc protocol AppJSExport: JSExport {
    static func createRequest(_ request: NSDictionary) -> Request
    static func createRequestManager(_ manager: JSValue) -> RequestManager
    static func createBookInfo(_ bookInfo: NSDictionary) -> BookInfo
    static func createSourceBook(_ sourceBook: NSDictionary) -> SourceBook
    static func createPartialSourceBook(_ partialSourceBook: NSDictionary) -> PartialSourceBook
    static func createPagedResults(_ results: NSDictionary) -> PagedResults
    static func createHomeSection(_ results: NSDictionary) -> HomeSection
    static func createDownloadInfo(_ results: NSDictionary) -> DownloadInfo
    static func createSourceStateManager() -> SourceStateManager
}

/**
    -- https://stackoverflow.com/a/69606375
 */
class AppJS: NSObject, AppJSExport {
    static func createSourceStateManager() -> SourceStateManager {
        return SourceStateManager()
    }

    static func createDownloadInfo(_ results: NSDictionary) -> DownloadInfo {
        let filetype = results["filetype"] as? String ?? "epub"
        let link = results["link"] as? String ?? ""

        return DownloadInfo(link: link, filetype: filetype)
    }

    static func createHomeSection(_ results: NSDictionary) -> HomeSection {
        let id = results["id"] as? String ?? UUID().uuidString
        let title = results["title"] as? String ?? ""
        let items = (results["items"] as? [PartialSourceBook]) ?? []
        let containsMoreItems = results["containsMoreItems"] as? Bool ?? false

        return HomeSection(id: id, title: title, items: items, containsMoreItems: containsMoreItems)
    }

    static func createPagedResults(_ pagedResults: NSDictionary) -> PagedResults {
        let results = (pagedResults["results"] as? [PartialSourceBook]) ?? []
        let metadata = pagedResults["metadata"] as Any?

        return PagedResults(results: results, metadata: metadata)
    }

    static func createPartialSourceBook(_ partialSourceBook: NSDictionary) -> PartialSourceBook {
        let title = partialSourceBook["title"] as? String ?? ""
        let id = partialSourceBook["id"] as? String ?? UUID().uuidString
        let image = partialSourceBook["image"] as? String
        let author = partialSourceBook["author"] as? String

        return PartialSourceBook(id: id, title: title, image: image, author: author)
    }

    static func createRequest(_ request: NSDictionary) -> Request {
        let url = request["url"] as? String ?? "undefined"
        let method = request["method"] as? String ?? "undefined"

        return Request(url: url, method: method)
    }

    static func createRequestManager(_ manager: JSValue) -> RequestManager {
        let timeout = manager.objectForKeyedSubscript("requestTimeout").toNumber() as? Int
        let interceptor = manager.objectForKeyedSubscript("interceptor")

        var sourceInterceptor: SourceInterceptor? = nil

        let rm = RequestManager(
            requestTimeout: timeout ?? 20_000,
            interceptor: nil
        )

        if let interceptor = interceptor, interceptor.isUndefined == false {
            if let interceptRequest = interceptor.objectForKeyedSubscript("interceptRequest"),
               let interceptorJSMangaged = JSManagedValue(value: interceptRequest)
            {
                sourceInterceptor = SourceInterceptor(interceptRequest: interceptorJSMangaged)
                JSContext.current()!.virtualMachine.addManagedReference(interceptorJSMangaged, withOwner: rm)
            }
        }

        rm.interceptor = sourceInterceptor

        return rm
    }

    static func createBookInfo(_ bookInfo: NSDictionary) -> BookInfo {
        let title = bookInfo["title"] as? String ?? ""
        let author = bookInfo["title"] as? String
        let desc = bookInfo["desc"] as? String
        let image = bookInfo["image"] as? String
        let tags = bookInfo["tags"] as? [String]
        let downloadLinks = bookInfo["downloadLinks"] as? [DownloadInfo] ?? []

        return BookInfo(
            title: title,
            author: author,
            desc: desc,
            image: image,
            tags: tags,
            downloadLinks: downloadLinks
        )
    }

    static func createSourceBook(_ sourceBook: NSDictionary) -> SourceBook {
        let id = sourceBook["id"] as? String ?? ""
        let bookInfo = sourceBook["bookInfo"] as? BookInfo ?? BookInfo(title: "", downloadLinks: [])

        return SourceBook(id: id, bookInfo: bookInfo)
    }
}
