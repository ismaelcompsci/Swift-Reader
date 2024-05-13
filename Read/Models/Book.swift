//
//  Book.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import Foundation
import PDFKit
import RealmSwift
import SwiftReader

enum ListName: String, PersistableEnum {
    case wantToRead = "want_to_read"
    case completed
}

class BookTag: EmbeddedObject {
    @Persisted var name: String = ""

    static let example = BookTag(value: ["name": "Fantasy"])
}

public class Book: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var title = ""
    @Persisted var author: String?
    @Persisted var summary: String?
    @Persisted var tags: List<BookTag> = List()
    @Persisted var language: String?
    @Persisted var bookPath: String?
    @Persisted var coverPath: String?
    
    @Persisted var dateFinished: Date?
    @Persisted var addedAt: Date = .now
    @Persisted var updatedAt: Date = .now
    @Persisted var lastEngaged: Date?
    @Persisted var lists: List<ListName> = List()
    
    @Persisted var readingPosition: ReadingPosition?
    @Persisted var highlights: List<BookHighlight> = List()
}

extension Book {
    var fileType: String? {
        if let type = bookPath?.split(separator: ".").last {
            return String(type)
        }

        return nil
    }

    var fileSize: Double? {
        let documentsDir = URL.documentsDirectory
        guard let bookPath else {
            return nil
        }

        let path = documentsDir.appending(path: bookPath)

        return path.size
    }
}

public extension Book {
    func removeReadingPosition() {
        guard let realm = realm?.thaw() else {
            return
        }
        
        let thawedBook = self.thaw()
        
        try! realm.write {
            if thawedBook?.readingPosition != nil {
                thawedBook?.readingPosition = nil
            }
        }
    }
    
    func updateReadingPosition(page: PDFPage, document: PDFDocument) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        let totalPages = CGFloat(document.pageCount)
        let currentPageIndex = CGFloat(document.index(for: page))
        let updatedAt: Date = .now
        
        let book = self.thaw()
        
        try! realm.write {
            if book?.readingPosition == nil {
                book?.readingPosition = ReadingPosition()
                book?.readingPosition?.progress = currentPageIndex / totalPages
                book?.readingPosition?.updatedAt = updatedAt
                book?.readingPosition?.chapter = Int(currentPageIndex)
                
            } else {
                book?.readingPosition?.progress = currentPageIndex / totalPages
                book?.readingPosition?.updatedAt = updatedAt
                book?.readingPosition?.chapter = Int(currentPageIndex)
            }
        }
    }
    
    /// non-pdf books only
    func updateReadingPosition(with location: Relocate) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        let book = self.thaw()
        
        try? realm.write {
            if book?.readingPosition == nil {
                book?.readingPosition = ReadingPosition()
                book?.readingPosition?.progress = location.fraction
                book?.readingPosition?.updatedAt = location.updatedAt ?? .now
                book?.readingPosition?.epubCfi = location.cfi
            } else {
                book?.readingPosition?.progress = location.fraction
                book?.readingPosition?.updatedAt = location.updatedAt ?? .now
                book?.readingPosition?.epubCfi = location.cfi
            }
        }
    }
    
    func addHighlight(pdfHighlight: PDFHighlight) {
        guard let realm = realm?.thaw(), let newHightlight = BookHighlight(pdfHighlight: pdfHighlight) else {
            return
        }
        
        let book = self.thaw()
        
        try? realm.write {
            book?.highlights.append(newHightlight)
        }
    }
    
    func addHighlight(text: String, cfi: String, index: Int, label: String, addedAt: Date, updatedAt: Date) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        let book = self.thaw()
        
        try? realm.write {
            let pHighlight = BookHighlight()
            pHighlight.highlightText = text
            pHighlight.cfi = cfi
            pHighlight.chapter = index
            pHighlight.chapterTitle = label
            pHighlight.addedAt = addedAt
            pHighlight.updatedAt = updatedAt
            
            book?.highlights.append(pHighlight)
        }
    }
    
    func removeHighlight(withValue value: String) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        guard let index = highlights.firstIndex(where: { $0.cfi == value }) else {
            return
        }
        
        let book = self.thaw()
        try? realm.write {
            book?.highlights.remove(at: index)
        }
    }
    
    func removeHighlight(withId highlightId: String) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        guard let index = highlights.firstIndex(where: { $0.highlightId == highlightId }) else {
            return
        }
        let book = self.thaw()
        try? realm.write {
            book?.highlights.remove(at: index)
        }
    }
    
    func updateLastEngaged(_ time: Date) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        let book = self.thaw()
        try? realm.write {
            book?.lastEngaged = time
        }
    }
    
    internal func removeFromList(_ list: ListName) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        let book = self.thaw()
        try? realm.write {
            let index = book?.lists.firstIndex(of: list)
            
            if let index = index {
                book?.lists.remove(at: index)
                
                if list == .completed {
                    book?.dateFinished = nil
                }
            }
        }
    }
    
    internal func addToList(_ list: ListName) {
        guard let realm = realm?.thaw() else {
            return
        }
        
        let book = self.thaw()
        try? realm.write {
            book?.lists.append(list)
            
            if list == .completed {
                book?.dateFinished = .now
            }
        }
    }
}

extension Book {
    static let example1 = Book(
        value: [
            "title": "The Witcher",
            "author": "Test Author",
            "summary": "A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. A guy with white hair killin g monsters and stuff. ",
            "language": "en"
        ]
    )
    static let example2 = Book(
        value: [
            "title": "The Game of Thrones",
            "author": "Test Author",
            "summary": "A guy with white hair killin g monsters and stuff. But again",
            "language": "en"
        ]
    )

    static let shortExample = Book(
        value: [
            "title": "The Game of Thrones",
            "author": "Test Author",
            "language": "en",
            "tags": [BookTag.example]
        ]
    )

    static let exampleArray = [Book.example1, Book.example2]
}
