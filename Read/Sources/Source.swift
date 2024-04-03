//
//  Source.swift
//  Read
//
//  Created by Mirna Olvera on 3/27/24.
//

import Foundation
import SwiftData

@Model
class Source: Identifiable {
    var sourceInfo: SourceInfo
    var url: URL
    var id: String {
        sourceInfo.id
    }

    var path: String?

    init(url: URL) throws {
        self.url = url
        let data = try Data(contentsOf: url.appendingPathComponent("source.json"))
        let sourceInfo = try JSONDecoder().decode(SourceInfo.self, from: data)
        self.sourceInfo = sourceInfo
    }

    static var all: FetchDescriptor<Source> {
        FetchDescriptor<Source>(sortBy: [SortDescriptor(\.sourceInfo.name)])
    }
}

struct SourceInfo: Codable, Hashable {
    static func == (lhs: SourceInfo, rhs: SourceInfo) -> Bool {
        lhs.id == rhs.id
    }

    let id: String
    let name: String
    let websiteURL: String
    let info: String
    let interfaces: SourceInterfaces
    let version: String

    var sourceUrl: URL?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.websiteURL = try container.decode(String.self, forKey: .websiteURL)
        self.info = try container.decode(String.self, forKey: .info)
        self.interfaces = try container.decode(SourceInterfaces.self, forKey: .interfaces)
        self.version = try container.decode(String.self, forKey: .version)
        self.sourceUrl = try container.decodeIfPresent(URL.self, forKey: .sourceUrl)
    }
}

struct SourceInterfaces: Codable, Hashable {
    var homePage: Bool
    var downloads: Bool
    var search: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.homePage = try container.decode(Bool.self, forKey: .homePage)
        self.downloads = try container.decode(Bool.self, forKey: .downloads)
        self.search = try container.decode(Bool.self, forKey: .search)
    }
}
