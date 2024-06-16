//
//  SDTag.swift
//  Read
//
//  Created by Mirna Olvera on 6/16/24.
//

import Foundation
import SwiftData

@Model
class SDTag {
    @Attribute(.unique) var id: UUID
    var name: String

    init(name: String) {
        id = .init()

        self.name = name
    }
}
