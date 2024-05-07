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
    static func createRequest(_ info: JSValue) -> Request
    static func createRequestManager(_ info: JSValue) -> RequestManager
    static func createBookInfo(_ info: JSValue) -> BookInfo
    static func createSourceBook(_ info: JSValue) -> SourceBook
    static func createPartialSourceBook(_ info: JSValue) -> PartialSourceBook
    static func createPagedResults(_ info: JSValue) -> PagedResults
    static func createHomeSection(_ info: JSValue) -> HomeSection
    static func createDownloadInfo(_ info: JSValue) -> DownloadInfo
    static func createSourceStateManager() -> SourceStateManager

    static func createUISection(_ info: JSValue) -> UISection
    static func createUIButton(_ info: JSValue) -> UIButton
    static func createUINavigationButton(_ info: JSValue) -> UINavigationButton
    static func createUIForm(_ info: JSValue) -> UIForm
    static func createUIInputField(_ info: JSValue) -> UIInputField
    static func createUIMultilineLabel(_ info: JSValue) -> UIMultilineLabel
}

class AppJS: NSObject, AppJSExport {
    static func createSecureStateManager() -> SecureStateManager {
        return SecureStateManager()
    }

    static func createSourceStateManager() -> SourceStateManager {
        return SourceStateManager()
    }

    static func createDownloadInfo(_ info: JSValue) -> DownloadInfo {
        let filetype = info.forProperty("filetype").toString() ?? "epub"
        let link = info.forProperty("link").toString() ?? ""

        return DownloadInfo(link: link, filetype: filetype)
    }

    static func createHomeSection(_ info: JSValue) -> HomeSection {
        let id = info.forProperty("id").toString() ?? UUID().uuidString
        let title = info.forProperty("title").toString() ?? ""
        let items = (info.forProperty("items").toArray() as? [PartialSourceBook]) ?? []
        let containsMoreItems = info.forProperty("containsMoreItems").toBool()

        return HomeSection(id: id, title: title, items: items, containsMoreItems: containsMoreItems)
    }

    static func createPagedResults(_ info: JSValue) -> PagedResults {
        let results = (info.forProperty("results").toArray() as? [PartialSourceBook]) ?? []
        let metadata = info.forProperty("metadata").toObject()
        return PagedResults(results: results, metadata: metadata)
    }

    static func createPartialSourceBook(_ info: JSValue) -> PartialSourceBook {
        let title = info.forProperty("title").toString() ?? "Unknown Title"
        let id = info.forProperty("id").toString() ?? UUID().uuidString
        let image = info.forProperty("image").toString()
        let author = info.forProperty("author").toString() ?? "Unknown Author"

        return PartialSourceBook(id: id, title: title, image: image, author: author)
    }

    static func createRequest(_ info: JSValue) -> Request {
        let url = info.forProperty("url").toString() ?? "undefined"
        let method = info.forProperty("method").toString() ?? "undefined"
        let data = info.forProperty("data")
        let headers = info.forProperty("headers").toDictionary() as? [String: String]

        var dataString: String? = nil

        if let data = data, data.isUndefined == false {
            dataString = data.toString()
        }

        return Request(url: url, method: method, data: dataString, headers: headers)
    }

    static func createRequestManager(_ info: JSValue) -> RequestManager {
        let timeout = info.forProperty("requestTimeout").toNumber() as? Int

        var interceptor: JSValue? = nil

        if info.hasProperty("interceptor") {
            interceptor = info.forProperty("interceptor")
        }

        let rm = RequestManager(
            requestTimeout: timeout ?? 20_000,
            interceptor: interceptor
        )

        return rm
    }

    static func createBookInfo(_ info: JSValue) -> BookInfo {
        let title = info.forProperty("title").toString() ?? "Unknown Title"
        let author = info.forProperty("author").toString() ?? "Unknown Author"
        let desc = info.forProperty("desc").toString()
        let image = info.forProperty("image").toString()
        let tags = info.forProperty("tags").toArray() as? [String]
        let downloadLinks = info.forProperty("downloadLinks").toArray() as? [DownloadInfo] ?? []

        return BookInfo(
            title: title,
            author: author,
            desc: desc,
            image: image,
            tags: tags,
            downloadLinks: downloadLinks
        )
    }

    static func createSourceBook(_ info: JSValue) -> SourceBook {
        let id = info.forProperty("id").toString() ?? ""
        let bookInfo = info.forProperty("bookInfo").toObjectOf(BookInfo.self) as? BookInfo ?? BookInfo(title: "", downloadLinks: [])

        return SourceBook(id: id, bookInfo: bookInfo)
    }
}

// MARK: JS UI

extension AppJS {
//    static func createUIBinding(_ info: JSValue) -> UIBinding {
//        return UIBinding()
//    }

    static func createUIMultilineLabel(_ info: JSValue) -> UIMultilineLabel {
        let id = info.forProperty("id")
        let label = info.forProperty("label")
        let value = info.forProperty("value")

        let multilineLabel = UIMultilineLabel(id: id?.toString() ?? UUID().uuidString)
        multilineLabel.setProp("id", id)
        multilineLabel.setProp("label", label)
        multilineLabel.setProp("value", value)

        return multilineLabel
    }

    static func createUIInputField(_ info: JSValue) -> UIInputField {
        let id = info.forProperty("id")
        let label = info.forProperty("label")
        let value = info.forProperty("value")

        let input = UIInputField(id: id?.toString() ?? UUID().uuidString)
        input.setProp("id", id)
        input.setProp("label", label)
        input.setProp("value", value)

        return input
    }

    static func createUIForm(_ info: JSValue) -> UIForm {
        let id = info.forProperty("id")
        let sections = info.forProperty("sections")
        let onSubmit = info.forProperty("onSubmit")

        let form = UIForm(id: id?.toString() ?? UUID().uuidString)

        sections?.call(completion: { result in
            switch result {
            case .success(let success):
                if let children = success, let children = children.toArray() as? [AnyUI] {
                    form.setChildren(children)
                }
            case .failure:
                Logger.js.warning("Failure making uiform sections children")
            }
        })

        form.setProp("onSubmit", onSubmit)
        form.setProp("id", id)

        return form
    }

    static func createUINavigationButton(_ info: JSValue) -> UINavigationButton {
        let id = info.forProperty("id")
        let label = info.forProperty("label")
        let form = info.forProperty("form")

        let navigationButton = UINavigationButton(id: id?.toString() ?? UUID().uuidString)
        navigationButton.setProp("label", label)
        navigationButton.setProp("id", id)

        if let children = form, let children = children.toObjectOf(AnyUI.self) as? AnyUI {
            navigationButton.setChildren([children])
        }

        return navigationButton
    }

    static func createUIButton(_ info: JSValue) -> UIButton {
        let id = info.forProperty("id")

        let button = UIButton(id: id?.toString() ?? UUID().uuidString)
        button.setProp("id", id)
        button.setProp("label", info.forProperty("label"))
        button.setProp("onTap", info.forProperty("onTap"))

        return button
    }

    static func createUISection(_ info: JSValue) -> UISection {
        let id = info.forProperty("id")
        let title = info.forProperty("title")
        let isHidden = info.forProperty("isHidden")
        let rows = info.forProperty("rows")

        let section = UISection(id: id?.toString() ?? UUID().uuidString)

        section.setProp("id", id)
        section.setProp("title", title)
        section.setProp("isHidden", isHidden)
        section.setProp("rows", rows)

        rows?.call(completion: { result in
            switch result {
            case .success(let success):
                if let children = success, let children = children.toArray() as? [AnyUI] {
                    section.setChildren(children)
                }
            case .failure:
                Logger.js.warning("Failure making ui section children")
            }
        })

        return section
    }
}
