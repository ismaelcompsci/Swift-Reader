//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/22/24.
//

import Foundation

/// A Link to a resource.
public struct SRLink {
    public let href: String
    public let title: String?
    public let type: BookType?
    public let children: [SRLink]

    public init(
        href: String,
        title: String? = nil,
        type: BookType? = nil,
        children: [SRLink] = []
    ) {
        self.href = href
        self.title = title
        self.type = type
        self.children = children
    }
}

/**
 https://github.com/readium/swift-toolkit/blob/develop/Sources/Shared/Publication/Locator.swift#L11
 */
public struct SRLocator: Hashable, CustomStringConvertible, Codable {
    public var type: BookType
    public var title: String
    public var locations: SRLocations
    public var text: String?

    public init(
        type: BookType,
        title: String = "",
        locations: SRLocations = .init(),
        text: String? = nil
    ) {
        self.type = type
        self.title = title
        self.locations = locations
        self.text = text
    }

    public var json: [String: Any] {
        [
            "type": type.rawValue,
            "title": encodeIfNotNil(title),
            "locations": encodeIfNotEmpty(locations.json),
            "text": encodeIfNotNil(text),
        ]
    }

    public var jsonString: String? {
        return serializeJSONString(json)
    }

    public var description: String { jsonString ?? "{}" }

    public init?(jsonString: String) {
        do {
            let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [String: Any]

            guard let json = json, let typeString = json["type"] as? String else {
                return nil
            }

            guard let typeInt = Int(typeString), let type = BookType(rawValue: typeInt) else {
                return nil
            }

            self.init(
                type: type,
                title: json["title"] as? String ?? "",
                locations: SRLocations(jsonString: json["locations"] as? String),
                text: json["text"] as? String
            )

        } catch {
            return nil
        }
    }
}

public enum BookType: Int, Hashable, Codable {
    case book
    case pdf
}

public struct SRLocations: Hashable, Codable {
    public var fragments: [String]
    public var progression: Double?
    public var totalProgression: Double?
    public var position: Int?

    public var json: [String: Any] {
        makeJSON([
            "fragments": encodeIfNotEmpty(fragments),
            "progression": encodeIfNotNil(progression),
            "totalProgression": encodeIfNotNil(totalProgression),
            "position": encodeIfNotNil(position),
        ])
    }

    public var jsonString: String? { serializeJSONString(json) }

    public init(
        fragments: [String] = [],
        progression: Double? = nil,
        totalProgression: Double? = nil,
        position: Int? = nil

    ) {
        self.fragments = fragments
        self.progression = progression
        self.totalProgression = totalProgression
        self.position = position
    }

    public init(jsonString: String?) {
        guard let jsonString = jsonString else {
            self.init()
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [String: Any]

            guard let json = json else {
                self.init()
                return
            }

            self.init(
                fragments: json["fragments"] as? [String] ?? [],
                progression: json["progression"] as? Double,
                totalProgression: json["totalProgression"] as? Double,
                position: json["position"] as? Int
            )
        } catch {
            self.init()
        }
    }
}

public struct SRHighlight: Codable {
    public var id: String
    public var locator: SRLocator
    public var color: HighlightColor
    public var created: Date = .init()
    public var progression: Double?

    public init(
        id: String,
        locator: SRLocator,
        color: HighlightColor,
        created: Date = Date()
    ) {
        self.id = id
        self.locator = locator
        self.color = color
        self.created = created
        self.progression = locator.locations.totalProgression
    }
}

public struct SRSelection {
    public var locator: SRLocator
    public var frame: CGRect
}
