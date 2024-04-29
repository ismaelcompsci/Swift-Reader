//
//  SRSourceActor.swift
//  Read
//
//  Created by Mirna Olvera on 4/29/24.
//

import Foundation
import JavaScriptCore

actor SRSourceActor {
    var source: SRExtension

    init(source: SRExtension) {
        self.source = source
    }

    func getBookDetails(for id: String) async throws -> SourceBook {
        try await source.extensionClass.invokeAsyncMethod(methodKey: "getBookDetails", args: [id])
    }

    func getSearchResults(query: SearchRequest, metadata: Any) async throws -> PagedResults {
        try await source.extensionClass.invokeAsyncMethod(methodKey: "getSearchResults", args: [query, metadata])
    }

    func getViewMoreItems(homepageSectionId: String, metadata: Any?) async throws -> PagedResults {
        try await source.extensionClass.invokeAsyncMethod(methodKey: "getViewMoreItems", args: [homepageSectionId, metadata as Any])
    }

    func getHomePageSections(sectionCallback: @escaping (Result<HomeSection, ExtensionError>) -> Void) {
        guard source.extensionClass.hasProperty("getHomePageSections") else {
            sectionCallback(.failure(.invalidPropertyInSource))
            return
        }

        let callback: @convention(block) (HomeSection?) -> Void = { result in

            if let result {
                sectionCallback(.success(result))

            } else {
                sectionCallback(.failure(.invalidHomeSection))
            }
        }

        let callbackFn = JSValue(object: callback, in: source.context)

        if let callbackFn {
            source.extensionClass.invokeMethod("getHomePageSections", withArguments: [callbackFn])
        }
    }
}
