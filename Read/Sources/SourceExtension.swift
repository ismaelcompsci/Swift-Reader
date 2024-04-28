//
//  SourceExtension.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

protocol ExtensionProtocol {
    func getBookDetails(for id: String) async throws -> SourceBook
    func getSearchResults(query: SearchRequest, metadata: Any) async throws -> PagedResults
    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async throws -> PagedResults
    func getHomePageSections(sectionCallback: @escaping (Result<HomeSection, ExtensionError>) -> Void)
}

enum ExtensionError: String, Error {
    case invalidHomeSection = "Unable to get home section from extension."
    case invalidSourceExtension = "Source extension was never initialized."
    case invalidPropertyInSource = "Source extension does not have the property."
    case invalidContext = "JSContext failed to load."
    case invalid = "Something went wrong with extension"
}

@Observable
class SourceExtension: NSObject {
    var context: JSContext?
    var sourceURL: URL
    var source: JSValue?
    var cheerio: JSValue?

    var sourceInfo: SourceInfo

    var loaded = false

    var extensionName: String {
        sourceInfo.name
    }

    init(sourceURL: URL, sourceInfo: SourceInfo) {
        self.sourceInfo = sourceInfo
        self.sourceURL = sourceURL
    }

    func initialiseSource() -> Bool {
        let inited = initialiseContext()
        let load = loadExtension()
        loaded = inited && load

        return inited && load
    }

    func initialiseContext() -> Bool {
        context = JSContext()
        context?.name = extensionName
        /* DEBUG */
        context?.isInspectable = true

        // Loading CheerioJS
        guard let baseJS = Bundle.main.path(forResource: "bundle", ofType: "js") else {
            Log("NO CHEERIO FOUND IN BUNDLE")
            return false
        }

        do {
            var jsString = try String(contentsOfFile: baseJS, encoding: .utf8)

            jsString.append("; cheerio;") // needed to get the JSValue of cheerio
            cheerio = context?.evaluateScript(jsString)

        } catch {
            Log("Error while processing script file: \(error)")
            return false
        }

        context?.setObject(
            Console.self,
            forKeyedSubscript: "console" as NSCopying & NSObjectProtocol
        )

        context?.exceptionHandler = { (_: JSContext!, value: JSValue!) in

            let stacktrace = value.objectForKeyedSubscript("stack").toString() ?? ""

            let lineNumber = value.objectForKeyedSubscript("line") ?? JSValue()

            let column = value.objectForKeyedSubscript("column") ?? JSValue()
            let moreInfo = "in method \(stacktrace)Line number in file: \(lineNumber), column: \(column)"
            Log("JS ERROR: \(value ?? JSValue()) \(moreInfo)")
        }

        context?.setObject(AppJS.self, forKeyedSubscript: "App" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(Request.self, forKeyedSubscript: "Request" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(Response.self, forKeyedSubscript: "Response" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(RequestManager.self, forKeyedSubscript: "RequestManager" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(BookInfo.self, forKeyedSubscript: "BookInfo" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(SourceBook.self, forKeyedSubscript: "SourceBook" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(SearchRequest.self, forKeyedSubscript: "SearchRequest" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(PartialSourceBook.self, forKeyedSubscript: "PartialSourceBook" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(HomeSection.self, forKeyedSubscript: "HomeSection" as (NSCopying & NSObjectProtocol)?)
        context?.setObject(SourceStateManager.self, forKeyedSubscript: "SourceStateManager"as (NSCopying & NSObjectProtocol)?)
        context?.setObject(SourceInterceptor.self, forKeyedSubscript: "SourceInterceptor"as (NSCopying & NSObjectProtocol)?)

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
}

extension SourceExtension: ExtensionProtocol {
    func getBookDetails(for id: String) async throws -> SourceBook {
        try await source!.invokeAsyncMethod(methodKey: "getBookDetails", args: [id])
    }

    func getSearchResults(query: SearchRequest, metadata: Any) async throws -> PagedResults {
        try await source!.invokeAsyncMethod(methodKey: "getSearchResults", args: [query, metadata])
    }

    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async throws -> PagedResults {
        try await source!.invokeAsyncMethod(methodKey: "getViewMoreItems", args: [homepageSectionId, metadata as Any])
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
