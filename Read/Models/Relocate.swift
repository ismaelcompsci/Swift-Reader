//
//  Relocate.swift
//  Read
//
//  Created by Mirna Olvera on 2/8/24.
//

import Foundation

struct Relocate: Codable, Equatable, Identifiable {
    var id: String {
        "\(cfi)-\(updatedAt)-\(fraction)"
    }

    var cfi: String
    var fraction: Double
    var updatedAt: Date
    var location: Location
//    var pageItem:
    var section: Section
    var time: Time
    var tocItem: TocItem

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cfi = try container.decode(String.self, forKey: .cfi)
        self.fraction = try container.decode(Double.self, forKey: .fraction)

        if let updateAtEpochTime = try container.decodeIfPresent(Int.self, forKey: .updatedAt) {
            let time = Date(timeIntervalSince1970: TimeInterval(updateAtEpochTime / 1000))
            self.updatedAt = time
        } else {
            self.updatedAt = .now
        }

        self.location = try container.decode(Location.self, forKey: .location)
        self.section = try container.decode(Section.self, forKey: .section)
        self.time = try container.decode(Time.self, forKey: .time)
        self.tocItem = try container.decode(TocItem.self, forKey: .tocItem)
    }

    static func == (lhs: Relocate, rhs: Relocate) -> Bool {
        lhs.fraction == rhs.fraction && lhs.updatedAt == rhs.updatedAt
    }
}

struct Location: Codable {
    var current: Int
    var next: Int
    var total: Int
}

struct Section: Codable {
    var current: Int
    var total: Int
}

struct Time: Codable {
    var section: Double
    var total: Double
}

struct TocItem: Codable {
    var label: String
    var href: String
    var subItems: [TocItem]?
    var id: Int
}
