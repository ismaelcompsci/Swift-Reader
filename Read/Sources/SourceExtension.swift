//
//  SourceExtension.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import JavaScriptCore

protocol ExtensionProtocol {
    func getBookDetails(for id: String) async throws -> SourceBook?
    func getSearchResults(query: SearchRequest, metadata: Any?) async throws -> PagedResults?
    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async throws -> PagedResults?
    func getHomePageSections(sectionCallback: @escaping (_ section: HomeSection?) -> Void)
}

enum ApplicationError: Error {
    case getBookDetailsError(String)
    case getViewMoreItems(String)
    case getSearchResults(String)
    case unexpected(String)
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

    func getBookDetails(for id: String) async throws -> SourceBook? {
        guard let source, source.hasProperty("getBookDetails"), let context else {
            return nil
        }

        guard let result = try await withUnsafeThrowingContinuation({ continuation in
            let callback: @convention(block) (SourceBook?) -> Void = { results in
                if let results {
                    continuation.resume(returning: results)
                    return
                }

                continuation.resume(
                    throwing: ApplicationError.getSearchResults("getBookDetails @convention(block) recived no data")
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
                    throwing: ApplicationError.getBookDetailsError("thenWrapper failed to execute")
                )
            }

            promise?.invokeMethod("then", withArguments: [thenWrapper])

        }) else {
            throw NSError(domain: "Extensable", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        }

        return result
    }

    func getSearchResults(query: SearchRequest, metadata: Any?) async throws -> PagedResults? {
        guard let source, source.hasProperty("getSearchResults"), let context else {
            return nil
        }

        guard let result = try await withUnsafeThrowingContinuation({ continuation in

            let callback: @convention(block) (PagedResults?) -> Void = { results in
                if let results {
                    continuation.resume(returning: results)
                    return
                }

                continuation.resume(throwing: ApplicationError.getViewMoreItems("Something went wrong"))
            }

            context.setObject(callback, forKeyedSubscript: "getSearchResultsCallback" as NSString)

            let promise = source.invokeMethod("getSearchResults", withArguments: [query, metadata])

            let thenWrapper = context.evaluateScript("""
            (e) => {
                getSearchResultsCallback(e)
            };
            """)

            guard let thenWrapper else {
                return continuation.resume(throwing: ApplicationError.getViewMoreItems("thenWrapper failed to execute"))
            }

            promise?.invokeMethod("then", withArguments: [thenWrapper])
        }) else {
            throw NSError(domain: "Extensable", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        }

        return result
    }

    func getHomePageSections(sectionCallback: @escaping (HomeSection?) -> Void) {
        guard let source, source.hasProperty("getHomePageSections"), let context else {
            return
        }

        let callback: @convention(block) (HomeSection?) -> Void = { result in
            sectionCallback(result)
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

    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async throws -> PagedResults? {
        guard let source, source.hasProperty("getViewMoreItems"), let context else {
            return nil
        }

        guard let result = try await withUnsafeThrowingContinuation({ continuation in

            let callback: @convention(block) (PagedResults?) -> Void = { results in
                if let results {
                    continuation.resume(returning: results)
                    return
                }

                continuation.resume(throwing: ApplicationError.getSearchResults("Something went wrong"))
            }

            context.setObject(
                callback,
                forKeyedSubscript: "getViewMoreItemsCallback" as NSString
            )

            let promise = source.invokeMethod(
                "getViewMoreItems",
                withArguments: [
                    homepageSectionId,
                    metadata
                ]
            )

            let thenWrapper = context.evaluateScript("""
            (e) => {
                getViewMoreItemsCallback(e)
            };
            """)

            guard let thenWrapper else {
                return continuation.resume(throwing: ApplicationError.getSearchResults("thenWrapper failed to execute"))
            }

            promise?.invokeMethod("then", withArguments: [thenWrapper])
        }) else {
            throw NSError(domain: "Extensable", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        }

        return result
    }
}
