//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/19/24.
//

import Foundation
import PDFKit

public class FoliateToc: Identifiable, Codable {
    public var href: String
    public var id: Int
    public var label: String
    public var subitems: [FoliateToc]?

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.href = try container.decode(String.self, forKey: .href)
        self.id = try container.decode(Int.self, forKey: .id)
        self.label = try container.decode(String.self, forKey: .label)
        self.subitems = try container.decodeIfPresent([FoliateToc].self, forKey: .subitems)
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
public struct Annotation: Codable {
    public var index: Int // index of loaded document in foliate-js
    public var value: String // cfi range  "epubcfi(/6/12!/4/12,/1:16,/1:354)"
    public var color: String

    public init(index: Int, value: String, color: String) {
        self.index = index
        self.value = value
        self.color = color
    }
}

public struct TappedHighlight: Codable {
    public var dir: String
    public var height: Double
    public var index: Int
    public var text: String
    public var value: String
    public var width: Double
    public var color: String
    public var y: Double
    public var x: Double
}

public struct Selection: Codable {
    public var bounds: CGRect
    public var string: String?
    public var dir: String?
}

struct FoliateSelection: Codable {
    var text: String
    var x: Double
    var y: Double
    var height: Double
    var width: Double
    var dir: String
    var value: String
    var index: Int

    static func toSelection(from selection: FoliateSelection) -> Selection {
        return Selection(
            bounds: CGRect(
                x: selection.x,
                y: selection.y,
                width: selection.width,
                height: selection.height
            ),
            string: selection.text,
            dir: selection.dir
        )
    }
}

public struct Relocate: Codable, Equatable, Identifiable {
    public var id: String {
        "\(cfi ?? "cfi")-\(updatedAt ?? .now)-\(fraction ?? 0.0)"
    }

    public var cfi: String?
    public var fraction: Double?
    public var updatedAt: Date?
    public var location: FoliateLocation?
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

        self.location = try container.decode(FoliateLocation.self, forKey: .location)
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

public struct FoliateLocation: Codable {
    public var current: Int
    public var next: Int
    public var total: Int
}

public struct BookSection: Codable {
    public var current: Int
    public var total: Int
}

public struct Time: Codable {
    public var section: Double
    public var total: Double
}

public struct FoliateHighlight: Codable {
    var index: Int
    var label: String?
    var cfi: String
    var text: String?

    static func toSRHighlight(
        from foliateHighlight: FoliateHighlight,
        with currentLocation: SRLocator?
    ) -> SRHighlight {
        let locations = SRLocations(
            fragments: [],
            progression: currentLocation?.locations.progression,
            totalProgression: currentLocation?.locations.totalProgression,
            position: currentLocation?.locations.position
        )

        let locater = SRLocator(
            type: .book,
            title: foliateHighlight.label ?? currentLocation?.title ?? "",
            locations: locations,
            text: foliateHighlight.text
        )

        return SRHighlight(
            id: UUID().uuidString,
            locator: locater,
            color: .yellow
        )
    }
}

public struct TappedPDFHighlight {
    public var bounds: CGRect
    public var UUID: UUID
}
