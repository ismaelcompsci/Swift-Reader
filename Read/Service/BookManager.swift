//
//  BookManager.swift
//  Read
//
//  Created by Mirna Olvera on 4/8/24.
//

import Foundation
import SReader
import SwiftData

enum BookImporterError: String, Error {
    case failedToGetMetadata = "Failed to get metadata"
}

@MainActor
class BookManager {
    static let shared = BookManager()
    let metadataExtractor = MetadataExtractor()
    var modelContext: ModelContext!

    private func downloadImage(with url: String) async -> URL? {
        guard let url = URL(string: url) else {
            return nil
        }

        do {
            let (file, _) = try await URLSession.shared.download(from: url)
            SRLogger.general.info("Downloaded image with url: \(url)")
            return file
        } catch {
            SRLogger.general.error("Failed to download image with url: \(url), error: \(error.localizedDescription)")
        }

        return nil
    }

    func process(for file: URL) async throws {
        let isPdf = file.lastPathComponent.hasSuffix(".pdf")

        var metadata: BookMetadata?

        if isPdf {
            metadata = await metadataExtractor.getPDFMetadata(from: file)
        } else {
            metadata = await metadataExtractor.getEbookMetadata(from: file)
        }

        guard let metadata = metadata else {
            throw BookImporterError.failedToGetMetadata
        }

        add(with: metadata, fromSource: false)
    }
}

extension BookManager {
    func add(with metadata: BookMetadata, fromSource: Bool) {
        let book = SDBook(
            id: .init(),
            title: metadata.title ?? "Unknown Title",
            author: metadata.author?.first?.name,
            summary: metadata.description,
            bookPath: metadata.bookPath,
            coverPath: metadata.bookCover
        )

        modelContext.insert(book)

        do {
            try modelContext.save()
        } catch { SRLogger.general.error("Failed to save new book \(error.localizedDescription)") }
    }

    func delete(_ book: SDBook) {
        modelContext.delete(book)

        do {
            try modelContext.save()
            removeBookFromDisk(book: book)
        } catch { SRLogger.general.error("Failed to delete book \(error.localizedDescription)") }
    }
}

extension BookManager {
    func removeBookFromDisk(book: SDBook) {
        guard let bookPath = book.bookPath else {
            print("Book has no path")
            return
        }

        let fullBookPath = URL.documentsDirectory.appending(path: bookPath)
        let directoryPath = fullBookPath.deletingLastPathComponent()

        do {
            try FileManager.default.removeItem(at: directoryPath)
        } catch {
            SRLogger.general.error("Failed to remove book \(error.localizedDescription)")
        }
    }
}
