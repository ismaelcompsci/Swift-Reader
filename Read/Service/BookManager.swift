//
//  BookManager.swift
//  Read
//
//  Created by Mirna Olvera on 4/8/24.
//

import Foundation
import OSLog
import RealmSwift
import SwiftReader

enum BookImporterError: String, Error {
    case failedToGetMetadata = "Failed to get metadata"
}

class BookManager {
    static let shared = BookManager()
    @ObservedResults(Book.self) var books

    private func downloadImage(with url: String) async -> URL? {
        guard let url = URL(string: url) else {
            return nil
        }

        do {
            let (file, _) = try await URLSession.shared.download(from: url)
            Logger.general.info("Downloaded image with url: \(url)")
            return file
        } catch {
            Logger.general.error("Failed to download image with url: \(url), error: \(error.localizedDescription)")
        }

        return nil
    }

    func process(for file: URL, with bookInfo: BookInfo) async throws {
        Logger.general.info("Processing book with book info")

        let bookId = UUID()
        let documents = URL.documentsDirectory
        let bookPath = BookMetadataExtractor.shared.makeBookBasePath(bookId: bookId.uuidString)
        let destination = documents.appending(path: bookPath)

        try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        var coverPath: String?

        if let imageUrl = bookInfo.image,
           let downloadedImageUrl = await downloadImage(with: imageUrl)
        {
            let filename = downloadedImageUrl.lastPathComponent
            coverPath = "\(bookPath)/\(filename)"
            let newImageLocation = destination.appending(path: filename)

            do {
                try FileManager.default.moveItem(at: downloadedImageUrl, to: newImageLocation)
            } catch {
                Logger.general.error("Download image error: \(error.localizedDescription)")
            }
        }

        guard let fullDestinationPath = BookMetadataExtractor.shared.copyBook(from: file, id: bookId) else {
            try? FileManager.default.removeItem(at: destination)
            throw BookImporterError.failedToGetMetadata
        }

        let author = MetadataAuthor(name: bookInfo.author ?? "Unknown Author")

        let metadata = BookMetadata(
            title: bookInfo.title,
            author: [author],
            description: bookInfo.desc,
            subject: bookInfo.tags,
            bookPath: "\(bookPath)/\(fullDestinationPath.lastPathComponent)",
            bookCover: coverPath
        )

        append(with: metadata, fromSource: true)
    }

    func process(for file: URL) async throws {
        let isPdf = file.lastPathComponent.hasSuffix(".pdf")

        var metadata: BookMetadata?

        if isPdf {
            metadata = BookMetadataExtractor.shared.parsePDF(from: file)
        } else {
            metadata = await BookMetadataExtractor.shared.parseEBook(from: file)
        }

        guard let metadata = metadata else {
            throw BookImporterError.failedToGetMetadata
        }

        append(with: metadata, fromSource: false)
    }
}

extension BookManager {
    func append(with metadata: BookMetadata, fromSource: Bool) {
        let realm = try! Realm()

        try! realm.write {
            let newBook = Book()
            newBook.title = metadata.title ?? "Untitled"
            newBook.summary = metadata.description ?? ""
            newBook.coverPath = metadata.bookCover
            newBook.bookPath = metadata.bookPath
            newBook.bookFromSource = fromSource

            _ = metadata.subject?.map { item in
                let newTag = BookTag()
                newTag.name = item
                newBook.tags.append(newTag)
            }

            _ = metadata.author.map { author in
                author.map { author in
                    let newAuthor = Author()
                    newAuthor.name = author.name ?? "Unknown Author"
                    newBook.authors.append(newAuthor)
                }
            }

            $books.append(newBook)
        }
    }

    func delete(_ book: Book) {
        let thawedBook = book.thaw()

        if let thawedBook, let bookRealm = thawedBook.realm {
            try! bookRealm.write {
                bookRealm.delete(thawedBook)
            }

            removeBookFromDisk(book: book)
        }
    }
}

extension BookManager {
    func removeBookFromDisk(book: Book) {
        guard let bookPath = book.bookPath else {
            print("Book has no path")
            return
        }

        let fullBookPath = URL.documentsDirectory.appending(path: bookPath)
        let directoryPath = fullBookPath.deletingLastPathComponent()

        do {
            try FileManager.default.removeItem(at: directoryPath)
        } catch {
            Logger.general.error("Failed to remove book \(error.localizedDescription)")
        }
    }
}
