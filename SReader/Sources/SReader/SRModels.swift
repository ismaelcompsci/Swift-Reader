//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/22/24.
//

import Foundation

/// A Link to a resource.
public struct SRLink: Codable {
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

public struct SRLocator: Hashable, Codable {
    public var type: BookType
    public var title: String
    public var locations: SRLocations
    public var text: String?

    public init(
        type: BookType,
        title: String = "",
        locations: SRLocations = SRLocations(fragments: []),
        text: String? = nil
    ) {
        self.type = type
        self.title = title
        self.locations = locations
        self.text = text
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

    public init(fragments: [String], progression: Double? = nil, totalProgression: Double? = nil, position: Int? = nil) {
        self.fragments = fragments
        self.progression = progression
        self.totalProgression = totalProgression
        self.position = position
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
