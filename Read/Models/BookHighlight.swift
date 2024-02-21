//
//  BookHighlight.swift
//  Read
//
//  Created by Mirna Olvera on 2/19/24.
//

import Foundation
import RealmSwift

class BookHighlight: EmbeddedObject {
    @Persisted var cfi: String? // non-pdf
    @Persisted var position: List<PDFHighlight> = List() // pdf

    @Persisted var chapter: Int?
    @Persisted var chapterTitle: String?

    @Persisted var backgroundColor: String = "#FFFF00"

    @Persisted var highlightText: String?

    @Persisted var addedAt: Date = .now
    @Persisted var updatedAt: Date = .now
}

class PDFHighlight: EmbeddedObject {
    @Persisted var page: Int
    @Persisted var ranges: List<HighlightRange> = List()
}

class HighlightRange: EmbeddedObject {
    @Persisted var lowerBound: Int
    @Persisted var uppperBound: Int
}
