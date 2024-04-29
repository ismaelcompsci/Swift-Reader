//
//  ExtActor.swift
//  Read
//
//  Created by Mirna Olvera on 4/29/24.
//

import JavaScriptCore
import OSLog

class SRExtension: Identifiable {
    var sourceURL: URL
    var sourceInfo: SourceInfo

    var actor: SRSourceActor!

    var context: JSContext
    var cheerio: JSValue!
    var extensionClass: JSValue!

    var id: String {
        sourceInfo.id
    }

    init(sourceURL: URL, sourceInfo: SourceInfo) throws {
        self.sourceInfo = sourceInfo
        self.sourceURL = sourceURL

        self.context = JSContext()
        self.actor = SRSourceActor(source: self)

        // init context first
        try initialiseJSContext()
        try initialiseJSExtension()
    }

    func initialiseJSExtension() throws {
        let jsString = try? String(contentsOf: sourceURL.appending(path: "index.js"), encoding: .utf8)

        let name = sourceInfo.name
        guard let jsString = jsString else {
            Logger.js.warning("FAILED TO GET EXTENSION JS: \(name)")
            return
        }

        context.evaluateScript(jsString)

        let sourceClass = context.evaluateScript("source.\(sourceInfo.name)")
        if let extensionClass = sourceClass?.construct(withArguments: [cheerio!]) {
            self.extensionClass = extensionClass
        } else {
            throw ExtensionError.invalidSourceExtension
        }

        Logger.js.info("LOADED EXTENSION: \(name)")
    }

    func initialiseJSContext() throws {
        context.name = sourceInfo.name
        /* DEBUG */
        context.isInspectable = true

        guard let baseJS = Bundle.main.path(forResource: "bundle", ofType: "js") else {
            Logger.js.warning("Something went wrong trying to load the main js bundle")
            return
        }

        do {
            var jsString = try String(contentsOfFile: baseJS, encoding: .utf8)
            jsString.append("; cheerio;") // needed to get the JSValue of cheerio
            cheerio = context.evaluateScript(jsString)
        } catch {
            Logger.general.error("Error while processing script file: \(error)")
            return
        }

        if cheerio == nil {
            throw ExtensionError.invalidContext
        }

        context.setObject(
            Console.self,
            forKeyedSubscript: "console" as NSCopying & NSObjectProtocol
        )

        context.exceptionHandler = { (_: JSContext!, value: JSValue!) in

            let stacktrace = value.objectForKeyedSubscript("stack").toString() ?? ""

            let lineNumber = value.objectForKeyedSubscript("line") ?? JSValue()

            let column = value.objectForKeyedSubscript("column") ?? JSValue()
            let moreInfo = "in method \(stacktrace)Line number in file: \(lineNumber), column: \(column)"
            Logger.js.error("JS ERROR: \(value ?? JSValue()) \(moreInfo)")
        }

        exportJSObjects()
    }

    func exportJSObjects() {
        context.setObject(AppJS.self, forKeyedSubscript: "App" as (NSCopying & NSObjectProtocol)?)
        context.setObject(Request.self, forKeyedSubscript: "Request" as (NSCopying & NSObjectProtocol)?)
        context.setObject(Response.self, forKeyedSubscript: "Response" as (NSCopying & NSObjectProtocol)?)
        context.setObject(RequestManager.self, forKeyedSubscript: "RequestManager" as (NSCopying & NSObjectProtocol)?)
        context.setObject(BookInfo.self, forKeyedSubscript: "BookInfo" as (NSCopying & NSObjectProtocol)?)
        context.setObject(SourceBook.self, forKeyedSubscript: "SourceBook" as (NSCopying & NSObjectProtocol)?)
        context.setObject(SearchRequest.self, forKeyedSubscript: "SearchRequest" as (NSCopying & NSObjectProtocol)?)
        context.setObject(PartialSourceBook.self, forKeyedSubscript: "PartialSourceBook" as (NSCopying & NSObjectProtocol)?)
        context.setObject(HomeSection.self, forKeyedSubscript: "HomeSection" as (NSCopying & NSObjectProtocol)?)
        context.setObject(SourceStateManager.self, forKeyedSubscript: "SourceStateManager"as (NSCopying & NSObjectProtocol)?)
        context.setObject(SourceInterceptor.self, forKeyedSubscript: "SourceInterceptor"as (NSCopying & NSObjectProtocol)?)
    }
}

extension SRExtension {
    func getBookDetails(for id: String) async throws -> SourceBook {
        try await actor.getBookDetails(for: id)
    }

    func getSearchResults(query: SearchRequest, metadata: Any) async throws -> PagedResults {
        try await actor.getSearchResults(query: query, metadata: metadata)
    }

    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async throws -> PagedResults {
        try await actor.getViewMoreItems(homepageSectionId: homepageSectionId, metadata: metadata)
    }

    func getHomePageSections(sectionCallback: @escaping (Result<HomeSection, ExtensionError>) -> Void) {
        Task {
            await actor.getHomePageSections(sectionCallback: sectionCallback)
        }
    }
}

enum ExtensionError: String, Error {
    case invalidHomeSection = "Unable to get home section from extension."
    case invalidSourceExtension = "Source extension was never initialized."
    case invalidPropertyInSource = "Source extension does not have the property."
    case invalidContext = "JSContext failed to load."
    case invalid = "Something went wrong with extension"
}
