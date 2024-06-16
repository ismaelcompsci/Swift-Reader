//
//  SDPosition.swift
//  Read
//
//  Created by Mirna Olvera on 6/16/24.
//

import Foundation
import SReader
import SwiftData

@Model
class SDPosition {
    var type: BookType
    var title: String?
    var text: String?

    var fragments: [String]
    var progression: Double?
    var totalProgression: Double?
    var position: Int?

    init(_ locater: SRLocator) {
        type = locater.type
        title = locater.title
        text = locater.text

        fragments = locater.locations.fragments
        progression = locater.locations.progression
        totalProgression = locater.locations.totalProgression
        position = locater.locations.position
    }

    func toSRLocater() -> SRLocator {
        SRLocator(
            type: type,
            title: title ?? "",
            locations: .init(
                fragments: fragments,
                progression: progression,
                totalProgression: totalProgression,
                position: position
            ),
            text: text
        )
    }
}
