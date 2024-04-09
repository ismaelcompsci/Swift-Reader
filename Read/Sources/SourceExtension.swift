//
//  SourceExtension.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

protocol ExtensionProtocol {
    func getBookDetails(for id: String) async -> Result<SourceBook, ExtensionError>
    func getSearchResults(query: SearchRequest, metadata: Any?) async -> Result<PagedResults, ExtensionError>
    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async -> Result<PagedResults, ExtensionError>
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
            print("FAILED TO GET EXTENSION JS: \(sourceInfo.name)")
            return false
        }
        context?.evaluateScript(jsString)

        // init extension class
        let sourceClass = context?.evaluateScript("source.\(extensionName)")
        source = sourceClass?.construct(withArguments: [cheerio])

        print("LOADED EXTENSION: \(extensionName)")

        return true
    }

    func getBookDetails(for id: String) async -> Result<SourceBook, ExtensionError> {
        guard let context = context else {
            return .failure(.invalidContext)
        }

        guard let source = source, source.hasProperty("getBookDetails") else {
            return .failure(source == nil ? .invalidSourceExtension : .invalidPropertyInSource)
        }

        guard let result = try? await withUnsafeThrowingContinuation({ continuation in
            let callback: @convention(block) (SourceBook?) -> Void = { results in
                if let results {
                    continuation.resume(returning: results)
                    return
                }

                continuation.resume(
                    throwing: ExtensionError.invalidBookDetails
                )
            }

            context.setObject(callback, forKeyedSubscript: "getBookDetailsCallback" as NSString)

            let promise = source.invokeMethod("getBookDetails", withArguments: [id])

            let thenWrapper = context.evaluateScript("""
            (e) => {
                getBookDetailsCallback(e)
            };
            """)

            guard let thenWrapper else {
                return continuation.resume(
                    throwing: ExtensionError.invalidBookDetails
                )
            }

            promise?.invokeMethod("then", withArguments: [thenWrapper])

        }) else {
            print("\(#function) withUnsafeThrowingContinuation error")
            return .failure(.invalidBookDetails)
        }

        return .success(result)
    }

    func getSearchResults(query: SearchRequest, metadata: Any?) async -> Result<PagedResults, ExtensionError> {
        guard let context = context else {
            return .failure(.invalidContext)
        }

        guard let source = source, source.hasProperty("getSearchResults") else {
            return .failure(source == nil ? .invalidSourceExtension : .invalidPropertyInSource)
        }

        guard let results = try? await withCheckedThrowingContinuation({ continuation in
            let id = UUID().uuidString.replacingOccurrences(of: "-", with: "_")

            let callback: @convention(block) (PagedResults?) -> Void = { results in

                if let results = results {
                    continuation.resume(returning: results)
                    context.evaluateScript("""
                    delete gloablThis.getSearchResultsCallback\(id)
                    """)
                } else {
                    continuation.resume(throwing: ExtensionError.invalidPagedResults)
                }
            }

            context.setObject(callback, forKeyedSubscript: "getSearchResultsCallback\(id)" as NSString)

            let promise = source.invokeMethod("getSearchResults", withArguments: [query, metadata as Any])

            let thenWrapper = context.evaluateScript("""
            (e) => {
                getSearchResultsCallback\(id)(e)
            };
            """)

            guard let thenWrapper else {
                continuation.resume(throwing: ExtensionError.invalidPagedResults)
                return
            }

            promise?.invokeMethod("then", withArguments: [thenWrapper])
        }) else {
            return .failure(.invalidPagedResults)
        }

        return .success(results)
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

    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async -> Result<PagedResults, ExtensionError> {
        guard let context = context else {
            return .failure(.invalidContext)
        }

        guard let source = source, source.hasProperty("getViewMoreItems") else {
            return .failure(source == nil ? .invalidSourceExtension : .invalidPropertyInSource)
        }

        guard let result = try? await withUnsafeThrowingContinuation({ continuation in

            let callback: @convention(block) (PagedResults?) -> Void = { results in
                if let results {
                    continuation.resume(returning: results)
                    return
                }

                continuation.resume(throwing: ExtensionError.invalidViewMoreItems)
            }

            context.setObject(
                callback,
                forKeyedSubscript: "getViewMoreItemsCallback" as NSString
            )

            let promise = source.invokeMethod(
                "getViewMoreItems",
                withArguments: [
                    homepageSectionId,
                    metadata as Any
                ]
            )

            let thenWrapper = context.evaluateScript("""
            (e) => {
                getViewMoreItemsCallback(e)
            };
            """)

            guard let thenWrapper else {
                return continuation.resume(throwing: ExtensionError.invalidViewMoreItems)
            }

            promise?.invokeMethod("then", withArguments: [thenWrapper])
        }) else {
            return .failure(.invalidViewMoreItems)
        }

        return .success(result)
    }
}
