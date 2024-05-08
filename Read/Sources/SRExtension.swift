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

    var ctx: JSContext
    var cheerio: JSValue!
    var extensionClass: JSValue!

    var id: String {
        sourceInfo.id
    }

    init(sourceURL: URL, sourceInfo: SourceInfo) throws {
        self.sourceInfo = sourceInfo
        self.sourceURL = sourceURL

        self.ctx = JSContext()
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

        ctx.evaluateScript(jsString)

        let sourceClass = ctx.evaluateScript("source.\(sourceInfo.name)")
        if let extensionClass = sourceClass?.construct(withArguments: [cheerio!]) {
            self.extensionClass = extensionClass
        } else {
            throw ExtensionError.invalidSourceExtension
        }

        Logger.js.info("LOADED EXTENSION: \(name)")
    }

    func initialiseJSContext() throws {
        ctx.name = sourceInfo.name
        /* DEBUG */
        ctx.isInspectable = true

        guard let baseJS = Bundle.main.path(forResource: "bundle", ofType: "js") else {
            Logger.js.warning("Something went wrong trying to load the main js bundle")
            return
        }

        do {
            var jsString = try String(contentsOfFile: baseJS, encoding: .utf8)
            jsString.append("; cheerio;") // needed to get the JSValue of cheerio
            cheerio = ctx.evaluateScript(jsString)
        } catch {
            Logger.general.error("Error while processing script file: \(error)")
            return
        }

        if cheerio == nil {
            throw ExtensionError.invalidContext
        }

        ctx.setObject(
            Console.self,
            forKeyedSubscript: "console" as NSCopying & NSObjectProtocol
        )

        ctx.exceptionHandler = { (_: JSContext!, value: JSValue!) in

            let stacktrace = value.objectForKeyedSubscript("stack").toString() ?? ""

            let lineNumber = value.objectForKeyedSubscript("line") ?? JSValue()

            let column = value.objectForKeyedSubscript("column") ?? JSValue()
            let moreInfo = "in method \(stacktrace)Line number in file: \(lineNumber), column: \(column)"
            Logger.js.error("JS ERROR: \(value ?? JSValue()) \(moreInfo)")
        }

        exportJSObjects()
    }

    func exportJSObjects() {
        ctx.setObject(AppJS.self, forKeyedSubscript: "App" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(Request.self, forKeyedSubscript: "Request" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(Response.self, forKeyedSubscript: "Response" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(RequestManager.self, forKeyedSubscript: "RequestManager" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(BookInfo.self, forKeyedSubscript: "BookInfo" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(SourceBook.self, forKeyedSubscript: "SourceBook" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(SearchRequest.self, forKeyedSubscript: "SearchRequest" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(PartialSourceBook.self, forKeyedSubscript: "PartialSourceBook" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(HomeSection.self, forKeyedSubscript: "HomeSection" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(SourceStateManager.self, forKeyedSubscript: "SourceStateManager"as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(SourceInterceptor.self, forKeyedSubscript: "SourceInterceptor"as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(UISection.self, forKeyedSubscript: "UISection" as (NSCopying & NSObjectProtocol)?)
        ctx.setObject(UIButton.self, forKeyedSubscript: "UIButton" as (NSCopying & NSObjectProtocol)?)
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

    func getSourceMenu() async throws -> UISection? {
        try await actor.getSourceMenu()
    }
}

enum ExtensionError: String, Error {
    case invalidHomeSection = "Unable to get home section from extension."
    case invalidSourceExtension = "Source extension was never initialized."
    case invalidPropertyInSource = "Source extension does not have the property."
    case invalidContext = "JSContext failed to load."
    case invalid = "Something went wrong with extension"
}
