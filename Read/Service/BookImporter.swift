//
//  BookImporter.swift
//  Read
//
//  Created by Mirna Olvera on 4/8/24.
//

import Foundation
import RealmSwift
import SwiftReader
/*
 add function to pass default metadata so no need for metadata extractor
 // download cover
 // download to book path
 // the same as metadata extractor from swift reader
 */

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
            return file
        } catch {
            print("Error downloading image: \(error.localizedDescription)")
        }

        return nil
    }

    func process(for file: URL, with sourceBook: SourceBook) async throws {
        let bookId = UUID()
        let documents = URL.documentsDirectory
        let bookPath = BookMetadataExtractor.shared.makeBookBasePath(bookId: bookId.uuidString)
        let destination = documents.appending(path: bookPath)

        var coverPath: String?

        if let imageUrl = sourceBook.bookInfo.image,
           let downloadedImageUrl = await downloadImage(with: imageUrl)
        {
            let filename = downloadedImageUrl.lastPathComponent
            coverPath = "\(bookPath)/\(filename)"
            let newImageLocation = destination.appending(path: filename)

            try? FileManager.default.moveItem(at: downloadedImageUrl, to: newImageLocation)
        }

        guard let fullDestinationPath = BookMetadataExtractor.shared.copyBook(from: file, id: bookId) else {
            throw BookImporterError.failedToGetMetadata
        }

        let author = MetadataAuthor(name: sourceBook.bookInfo.author ?? "Unknown Author")

        let metadata = BookMetadata(
            title: sourceBook.bookInfo.title,
            author: [author],
            description: sourceBook.bookInfo.desc,
            subject: sourceBook.bookInfo.tags,
            bookPath: "\(bookPath)/\(fullDestinationPath.lastPathComponent)",
            bookCover: coverPath
        )

        addBook(with: metadata)
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

        addBook(with: metadata)
    }

    private func addBook(with metadata: BookMetadata) {
        let realm = try! Realm()

        try! realm.write {
            let newBook = Book()
            newBook.title = metadata.title ?? "Untitled"
            newBook.summary = metadata.description ?? ""
            newBook.coverPath = metadata.bookCover
            newBook.bookPath = metadata.bookPath

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

            newBook.processed = true

            $books.append(newBook)
        }
    }
}
