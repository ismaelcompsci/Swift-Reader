//
//  ReaderModels.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import Foundation
import PDFKit

protocol TocItem: Identifiable {
    var id: Int { get }
    var depth: Int? { get }
    var label: String { get }
}

protocol BaseAnnotation: Codable {
    var index: Int { get } // index of loaded document in foliate-js
    var value: String { get } // cfi range  "epubcfi(/6/12!/4/12,/1:16,/1:354)"
    var color: String { get }
}

struct PDFTocItem: TocItem {
    var id: Int {
        outline.hashValue
    }

    var outline: PDFOutline?
    var depth: Int?

    var label: String {
        outline?.label ?? ""
    }
}

struct EBookTocItem: Codable, Identifiable, TocItem {
    var label: String
    var href: String
    var id: Int

    var depth: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.href = try container.decode(String.self, forKey: .href)
        self.id = try container.decode(Int.self, forKey: .id)
        self.depth = try container.decode(Int.self, forKey: .depth)
    }
}

struct PDFHighlight {
    struct PageLocation: Codable {
        var page: Int
        var ranges: [NSRange]
    }

    var uuid: UUID
    var pos: [PageLocation]
    var content: String?
}

// minimal info to inject saved annotation into book
struct Annotation: BaseAnnotation {
    var index: Int // index of loaded document in foliate-js
    var value: String // cfi range  "epubcfi(/6/12!/4/12,/1:16,/1:354)"
    var color: String
}

struct TappedHighlight: BaseAnnotation {
    var index: Int
    var value: String
    var color: String
    var dir: String
    var text: String
    var x: Double
    var y: Double
}

struct Selection {
    var bounds: CGRect
    var string: String?
    var dir: String?
}

struct Relocate: Codable, Equatable, Identifiable {
    var id: String {
        "\(cfi ?? "cfi")-\(updatedAt ?? .now)-\(fraction ?? 0.0)"
    }

    var cfi: String?
    var fraction: Double?
    var updatedAt: Date?
    var location: Location?
    var section: Section?
    var time: Time?
    var tocItem: RelocateTocItem?

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
        self.tocItem = try container.decode(RelocateTocItem.self, forKey: .tocItem)
    }

    static func == (lhs: Relocate, rhs: Relocate) -> Bool {
        lhs.fraction == rhs.fraction && lhs.updatedAt == rhs.updatedAt
    }
}

struct RelocateTocItem: Codable {
    var label: String
    var href: String
    var id: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.href = try container.decode(String.self, forKey: .href)
        self.id = try container.decode(Int.self, forKey: .id)
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
