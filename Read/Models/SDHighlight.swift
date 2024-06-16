//
//  SDHighlight.swift
//  Read
//
//  Created by Mirna Olvera on 6/16/24.
//

import Foundation
import SReader
import SwiftData

@Model
class SDHighlight {
    @Attribute(.unique) var id: String

    var color: HighlightColor
    var created = Date()

    // SRLocator
    var fragments: [String]
    var progression: Double?
    var totalProgression: Double?
    var position: Int?

    var type: BookType
    var title: String
    var text: String?
    // SRLocator

    var book: SDBook?

    init(
        id: String,
        locator: SRLocator,
        color: HighlightColor,
        created: Date = .now,
        progression: Double? = nil
    ) {
        self.id = id
        self.color = color
        self.created = created

        self.fragments = locator.locations.fragments
        self.progression = locator.locations.progression
        self.totalProgression = locator.locations.totalProgression
        self.position = locator.locations.position
        self.type = locator.type
        self.title = locator.title
        self.text = locator.text

        self.book = nil
    }

    init(_ highlight: SRHighlight) {
        self.id = highlight.id
        self.color = highlight.color
        self.created = highlight.created
        self.progression = highlight.progression

        self.fragments = highlight.locator.locations.fragments
        self.totalProgression = highlight.locator.locations.totalProgression
        self.position = highlight.locator.locations.position
        self.type = highlight.locator.type
        self.title = highlight.locator.title
        self.text = highlight.locator.text
    }

    func toSRHiglight() -> SRHighlight {
        SRHighlight(
            id: self.id,
            locator: .init(
                type: self.type,
                title: self.title,
                locations: .init(
                    fragments: self.fragments,
                    progression: self.progression,
                    totalProgression: self.totalProgression,
                    position: self.position
                ),
                text: self.text
            ),
            color: self.color,
            created: self.created
        )
    }
}
