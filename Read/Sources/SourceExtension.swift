//
//  SourceExtension.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

protocol ExtensionProtocol {
    func getBookDetails(for id: String, completed: @escaping (Result<SourceBook, ExtensionError>) -> Void)
    func getSearchResults(query: SearchRequest, metadata: Any, completed: @escaping (Result<PagedResults, ExtensionError>) -> Void)
    func getViewMoreItems(homepageSectionId: String, metadata: Any?, completed: @escaping ((Result<PagedResults, ExtensionError>) -> Void))
    func getHomePageSections(sectionCallback: @escaping (Result<HomeSection, ExtensionError>) -> Void)
}

enum ApplicationError: Error {
    case getViewMoreItems(String)
    case getSearchResults(String)
    case unexpected(String)
}

enum ExtensionError: String, Error {
    case invalidBookDetails = "Unable to get book details from extension."
    case invalidPagedResults = "Unable to get paged details from extension."
    case invalidHomeSection = "Unable to get home section from extension."
    case invalidViewMoreItems = "Unable to get more items from extension."
    case invalidSourceExtension = "Source extension was never initialized."
    case invalidPropertyInSource = "Source extension does not have the property."
    case invalidContext = "JSContext failed to load."
    case invalid = "Something went wrong."
}

@Observable
class SourceExtension: NSObject, ExtensionProtocol {
    var extensionName: String
    var context: JSContext?
    var sourceURL: URL
    var source: JSValue?
    var cheerio: JSValue?

    var sourceInfo: SourceInfo

    var loaded = false

    init(extensionName: String, sourceURL: URL, sourceInfo: SourceInfo) {
        self.extensionName = extensionName
        self.sourceInfo = sourceInfo
        self.sourceURL = sourceURL

        super.init()
    }

    func load() -> Bool {
        let inited = initContext()
        let load = loadExtension()
        loaded = inited && load

        return inited && load
    }

    func initContext() -> Bool {
        context = JSContext()
        context?.name = extensionName
        /* DEBUG */
        context?.isInspectable = true

        // Loading CheerioJS
        guard let baseJS = Bundle.main.path(forResource: "bundle", ofType: "js") else {
            print("NO CHEERIO FOUND IN BUNDLE")
            return false
        }

        do {
            var jsString = try String(contentsOfFile: baseJS, encoding: .utf8)

            jsString.append("; cheerio;") // needed to get the JSValue of cheerio
            cheerio = context?.evaluateScript(jsString)

        } catch {
            print("Error while processing script file: \(error)")

            return false
        }

        context?.setObject(AppJS.self, forKeyedSubscript: "App" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(Request.self, forKeyedSubscript: "Request" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(Response.self, forKeyedSubscript: "Response" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(RequestManager.self, forKeyedSubscript: "RequestManager" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(BookInfo.self, forKeyedSubscript: "BookInfo" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(SourceBook.self, forKeyedSubscript: "SourceBook" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(SearchRequest.self, forKeyedSubscript: "SearchRequest" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(
            PartialSourceBook.self,
            forKeyedSubscript: "PartialSourceBook" as (NSCopying & NSObjectProtocol)?
        )
        context?.setObject(HomeSection.self, forKeyedSubscript: "HomeSection" as (NSCopying & NSObjectProtocol)?)

        return true
    }

    func getExtensionJS(from url: URL) -> String? {
        let jsString = try? String(contentsOf: url.appending(path: "index.js"), encoding: .utf8)

        return jsString
    }

    func loadExtension() -> Bool {
        guard let jsString = getExtensionJS(from: sourceURL), let cheerio else {
            Log("FAILED TO GET EXTENSION JS: \(sourceInfo.name)")
            return false
        }
        context?.evaluateScript(jsString)

        let sourceClass = context?.evaluateScript("source.\(extensionName)")
        source = sourceClass?.construct(withArguments: [cheerio])

        Log("LOADED EXTENSION: \(extensionName)")

        return true
    }

    func getSearchResults(
        query: SearchRequest,
        metadata: Any,
        completed: @escaping (Result<PagedResults, ExtensionError>) -> Void
    ) {
        Log("query: \(query)")
        executeAsyncJS(method: "getSearchResults", args: [query, metadata], completed: completed)
    }

    func getBookDetails(
        for id: String,
        completed: @escaping (Result<SourceBook, ExtensionError>) -> Void
    ) {
        executeAsyncJS(method: "getBookDetails", args: [id], completed: completed)
    }

    func getViewMoreItems(
        homepageSectionId: String,
        metadata: Any?,
        completed: @escaping ((Result<PagedResults, ExtensionError>) -> Void)
    ) {
        executeAsyncJS(method: "getViewMoreItems", args: [homepageSectionId, metadata as Any], completed: completed)
    }

    func executeAsyncJS<T: JSExport>(
        method: String,
        args: [Any],
        completed: @escaping ((Result<T, ExtensionError>) -> Void)
    ) {
        guard let context = context else {
            return completed(.failure(.invalidContext))
        }

        let successCallback: @convention(block) (JSExport) -> Void = { value in
            if let genericValue = value as? T {
                completed(.success(genericValue))
            } else {
                completed(.failure(.invalid))
            }
        }

        let failureCallback: @convention(block) (JSValue) -> Void = { value in
            Log("Failure in async js code: \(value)")
            completed(.failure(.invalid))
        }
        // TODO: MAKE EVERY CALLLBACK UNQUEE id uuidname
        context.setObject(successCallback, forKeyedSubscript: "jsSuccessHandler" as NSString)
        context.setObject(failureCallback, forKeyedSubscript: "jsFailureHandler" as NSString)

        let jsSuccessCallback = context.objectForKeyedSubscript("jsSuccessHandler")!
        let jsFailureCallback = context.objectForKeyedSubscript("jsFailureHandler")!

        guard let source, source.hasProperty(method) else {
            completed(.failure(source == nil ? .invalidSourceExtension : .invalidPropertyInSource))
            return
        }

        let promise = source.invokeMethod(method, withArguments: args)
        promise?.invokeMethod("then", withArguments: [jsSuccessCallback])
        promise?.invokeMethod("catch", withArguments: [jsFailureCallback])
    }

    func getHomePageSections(sectionCallback: @escaping (Result<HomeSection, ExtensionError>) -> Void) {
        guard let context = context else {
            sectionCallback(.failure(.invalidContext))
            return
        }

        guard let source = source, source.hasProperty("getHomePageSections") else {
            sectionCallback(.failure(source == nil ? .invalidSourceExtension : .invalidPropertyInSource))
            return
        }

        let callback: @convention(block) (HomeSection?) -> Void = { result in

            if let result {
                sectionCallback(.success(result))
            } else {
                sectionCallback(.failure(.invalidHomeSection))
            }
        }

        context.setObject(callback, forKeyedSubscript: "getHomePageSectionsCallback" as NSString)

        let callbackWrapper = context.evaluateScript("""
        (e) => {
            getHomePageSectionsCallback(e);
        }
        """)

        if let callbackWrapper {
            source.invokeMethod("getHomePageSections", withArguments: [callbackWrapper])
        }
    }
}
