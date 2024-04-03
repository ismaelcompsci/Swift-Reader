//
//  ReaderModels.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import Foundation
import PDFKit

public protocol TocItem: Identifiable {
    var id: Int { get }
    var depth: Int? { get }
    var label: String { get }

    var pageNumber: Int? { get }
}

protocol BaseAnnotation: Codable {
    var index: Int { get } // index of loaded document in foliate-js
    var value: String { get } // cfi range  "epubcfi(/6/12!/4/12,/1:16,/1:354)"
    var color: String { get }
}

public struct PDFTocItem: TocItem {
    public var id: Int {
        outline.hashValue
    }

    public var outline: PDFOutline?
    public var depth: Int?

    public var label: String {
        outline?.label ?? ""
    }

    public var pageNumber: Int? {
        outline?.destination?.page?.pageRef?.pageNumber
    }

    public init(outline: PDFOutline? = nil, depth: Int? = nil) {
        self.outline = outline
        self.depth = depth
    }
}

/// no pagenumber
public struct EBookTocItem: Codable, Identifiable, TocItem {
    public var label: String
    public var href: String
    public var id: Int

    public var depth: Int?

    public var pageNumber: Int?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.href = try container.decode(String.self, forKey: .href)
        self.id = try container.decode(Int.self, forKey: .id)
        self.depth = try container.decode(Int.self, forKey: .depth)
//        self.pageNumber = try container.decode(Int.self, forKey: .pageNumber)
    }
}

public struct PDFHighlight {
    public struct PageLocation: Codable {
        public var page: Int
        public var ranges: [NSRange]
    }

    public var uuid: UUID
    public var pos: [PageLocation]
    public var content: String?

    public init(uuid: UUID, pos: [PageLocation], content: String? = nil) {
        self.uuid = uuid
        self.pos = pos
        self.content = content
    }
}

// minimal info to inject saved annotation into book
public struct Annotation: BaseAnnotation {
    public var index: Int // index of loaded document in foliate-js
    public var value: String // cfi range  "epubcfi(/6/12!/4/12,/1:16,/1:354)"
    public var color: String

    public init(index: Int, value: String, color: String) {
        self.index = index
        self.value = value
        self.color = color
    }
}

public struct TappedHighlight: BaseAnnotation {
    public var index: Int
    public var value: String
    public var color: String
    public var dir: String
    public var text: String
    public var x: Double
    public var y: Double
}

public struct Selection {
    public var bounds: CGRect
    public var string: String?
    public var dir: String?
}

public struct Relocate: Codable, Equatable, Identifiable {
    public var id: String {
        "\(cfi ?? "cfi")-\(updatedAt ?? .now)-\(fraction ?? 0.0)"
    }

    public var cfi: String?
    public var fraction: Double?
    public var updatedAt: Date?
    public var location: Location?
    public var section: BookSection?
    public var time: Time?
    public var tocItem: RelocateTocItem?

    public init(from decoder: Decoder) throws {
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
        self.section = try container.decode(BookSection.self, forKey: .section)
        self.time = try container.decode(Time.self, forKey: .time)
        self.tocItem = try container.decode(RelocateTocItem.self, forKey: .tocItem)
    }

    public static func == (lhs: Relocate, rhs: Relocate) -> Bool {
        lhs.fraction == rhs.fraction && lhs.updatedAt == rhs.updatedAt
    }
}

public struct RelocateTocItem: Codable {
    public var label: String
    public var href: String
    public var id: Int

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.href = try container.decode(String.self, forKey: .href)
        self.id = try container.decode(Int.self, forKey: .id)
    }
}

public struct Location: Codable {
    var current: Int
    var next: Int
    var total: Int
}

public struct BookSection: Codable {
    var current: Int
    var total: Int
}

public struct Time: Codable {
    var section: Double
    var total: Double
}
