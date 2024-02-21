//
//  ReadingPosition.swift
//  Read
//
//  Created by Mirna Olvera on 2/19/24.
//

import Foundation
import RealmSwift

class ReadingPosition: EmbeddedObject {
    @Persisted var chapterProgress: Double?
    @Persisted var chapter: Int
    @Persisted var updatedAt: Date
    @Persisted var epubCfi: String?
    @Persisted var progress: Double?
}
