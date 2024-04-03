//
//  SourceManagaer.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import SwiftData
import ZIPFoundation

/**
 insparation from Aidoku
 https://github.com/Aidoku/Aidoku/blob/main/Shared/Sources/SourceManager.swift#L11
 */
@Observable
class SourceManager {
    static let directory = URL.documentsDirectory.appendingPathComponent("Sources", isDirectory: true)

    var modelContext: ModelContext

    var sources: [Source] = []
    var sourceLists: [URL] = []

    var extensions: [String: SourceExtension] = [:]

    private var sourceListsStrings: [String] {
        sourceLists.map { $0.absoluteString }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        let dbSources = try? self.modelContext.fetch(Source.all)

        if let dbSources {
            sources.append(contentsOf: dbSources)
        }

        self.sourceLists = (UserDefaults.standard.array(forKey: "Browse.sourceLists") as? [String] ?? [])
            .compactMap { URL(string: $0) }

        for source in sources {
            let ext = SourceManager.createExtension(from: source)
            extensions[source.id] = ext
        }
    }

    static func createExtension(from source: Source) -> SourceExtension {
        let sourceExt = SourceExtension(
            extensionName: source.sourceInfo.name,
            sourceURL: URL.documentsDirectory.appending(path: source.path!),
            sourceInfo: source.sourceInfo
        )

        let loaded = sourceExt.load()

        return sourceExt
    }

    func source(for id: String) -> Source? {
        sources.first { $0.id == id }
    }

    func remove(source: Source) {
        try? FileManager.default.removeItem(at: source.url)
        sources.removeAll { $0.id == source.id }
        extensions.removeValue(forKey: source.id)

        modelContext.delete(source)
    }

    func clearSources() {
        for source in sources {
            remove(source: source)
        }
    }

    func importSource(from url: URL) async -> Source? {
        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true, attributes: nil)

        let name = url.deletingPathExtension().lastPathComponent
        let tmpDir = FileManager.default.temporaryDirectory.appending(path: name)
        if let (fileURL, _) = try? await URLSession.shared.download(from: url) {
            try? FileManager.default.unzipItem(at: fileURL, to: tmpDir)
            try? FileManager.default.removeItem(at: fileURL)

            let payload = tmpDir
            let source = try? Source(url: payload)

            if let source {
                let destination = Self.directory.appending(path: source.id)

                source.url = destination
                source.sourceInfo.sourceUrl = url
                source.path = "Sources/\(source.id)"
                modelContext.insert(source)

                if destination.exists {
                    try? FileManager.default.removeItem(at: destination)
                    sources.removeAll { $0.id == source.id }
                }

                try? FileManager.default.moveItem(at: payload, to: destination)
                try? FileManager.default.removeItem(at: tmpDir)

                sources.append(source)
                let ext = SourceManager.createExtension(from: source)
                extensions[source.id] = ext

                return source
            }

            print("\(#function) Failed to create source")
        }

        return nil
    }

    // todo make the source a object that has name & url
    func addSourceList(url: URL) async -> Bool {
        guard sourceLists.contains(url) == false else {
            return false
        }

        if await loadSourceList(url: url) == nil {
            return false
        }

        sourceLists.append(url)
        UserDefaults.standard.set(sourceListsStrings, forKey: "Browse.sourceLists")

        return true
    }

    func removeSourceList(url: URL) {
        sourceLists.removeAll { $0 == url }
        UserDefaults.standard.set(sourceListsStrings, forKey: "Browse.sourceLists")
    }

    func clearSourceLists() {
        sourceLists = []
        UserDefaults.standard.set([URL](), forKey: "Browse.sourceLists")
    }

    func loadSourceList(url: URL) async -> [SourceInfo]? {
        var sourceInfo: [SourceInfo]?

        if url.pathExtension.isEmpty == false {
            if let data = try? await URLSession.shared.data(
                for: URLRequest(
                    url: url,
                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
                )
            ) {
                sourceInfo = try? JSONDecoder().decode([SourceInfo].self, from: data.0)
            }

        } else {
            if let data = try? await URLSession.shared.data(
                for: URLRequest(
                    url: url.appending(path: "sources.json"),
                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
                )
            ) {
                sourceInfo = try? JSONDecoder().decode([SourceInfo].self, from: data.0)
            }
        }

        return sourceInfo
    }
}
