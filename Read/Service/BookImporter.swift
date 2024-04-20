//
//  BookImporter.swift
//  Read
//
//  Created by Mirna Olvera on 4/8/24.
//

import Foundation
import RealmSwift
import SwiftReader

enum BookImporterError: String, Error {
    case failedToGetMetadata = "Failed to get metadata"
}

class BookImporter {
    static let shared = BookImporter()
    @ObservedResults(Book.self) var books

    private func downloadImage(with url: String) async -> URL? {
        guard let url = URL(string: url) else {
            return nil
        }

        do {
            let (file, _) = try await URLSession.shared.download(from: url)
            Log("Downloaded image with url: \(url)")
            return file
        } catch {
            Log("Failed to download image with url: \(url), error: \(error.localizedDescription)")
        }

        return nil
    }

    func process(for file: URL, with bookInfo: BookInfo) async throws {
        Log("Processing book with book info")

        let bookId = UUID()
        let documents = URL.documentsDirectory
        let bookPath = BookMetadataExtractor.shared.makeBookBasePath(bookId: bookId.uuidString)
        let destination = documents.appending(path: bookPath)

        try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        var coverPath: String?
        Log("book id \(bookId)")

        if let imageUrl = bookInfo.image,
           let downloadedImageUrl = await downloadImage(with: imageUrl)
        {
            Log("Downloaded image path exists: \(downloadedImageUrl.exists)")
            let filename = downloadedImageUrl.lastPathComponent
            coverPath = "\(bookPath)/\(filename)"
            let newImageLocation = destination.appending(path: filename)
            Log("NEW LOC: \(newImageLocation)")
            do {
                try FileManager.default.moveItem(at: downloadedImageUrl, to: newImageLocation)
            } catch {
                Log("Download image error: \(error.localizedDescription)")
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

        addBook(with: metadata, fromSource: true)
    }

    func process(for file: URL) async throws {
        Log("Processing book with local file.")
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

        addBook(with: metadata, fromSource: false)
    }

    private func addBook(with metadata: BookMetadata, fromSource: Bool) {
        let realm = try! Realm()

        try! realm.write {
            let newBook = Book()
            newBook.title = metadata.title ?? "Untitled"
            newBook.summary = metadata.description ?? ""
            newBook.coverPath = metadata.bookCover
            newBook.bookPath = metadata.bookPath
            newBook.bookFromSource = fromSource

            _ = metadata.subject?.map { item in
                let newTag = Tag()
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
}
