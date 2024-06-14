//
//  File.swift
//
//
//  Created by Mirna Olvera on 6/9/24.
//

import Foundation
import PDFKit

@MainActor
public final class MetadataExtractor {
    private let webView: HeadlessWebview
    public let booksFolder = URL.documentsDirectory.appending(path: "books", directoryHint: .isDirectory)

    public init() {
        webView = HeadlessWebview()
        loadMetadataExtractor()
        try? FileManager.default.createDirectory(at: booksFolder, withIntermediateDirectories: true)
    }

    public func loadMetadataExtractor() {
        _ = webView.loadMetadataExtractorJS()
    }

    private func parseBook(path: String) async throws -> BookMetadata? {
        let extracterName = "metadata"
        let script = """
        var \(extracterName) = new MetaDataExtractor()
        var promise = \(extracterName)?.initBook(`\(path)`);
        await promise;
        return promise;
        """

        guard let metadata = try await webView.webView.callAsyncJavaScript(script, contentWorld: .page) else {
            print("RETURNED EARYLY NO METADATA")
            return nil
        }
        let metadataString = String(describing: metadata)

        guard
            let data = metadataString.data(using: .utf8),
            let bookMetadata = try? JSONDecoder().decode(BookMetadata.self, from: data)
        else {
            return nil
        }

        return bookMetadata
    }

    public func getEbookMetadata(from url: URL) async -> BookMetadata? {
        guard url.pathExtension != "pdf" else {
            return nil
        }

        _ = url.startAccessingSecurityScopedResource()
        let bookId = UUID()

        guard let documentsBook = copyBook(from: url, id: bookId) else {
            url.stopAccessingSecurityScopedResource()
            return nil
        }

        do {
            guard var metadata = try await parseBook(path: documentsBook.absoluteString) else {
                return nil
            }

            // save cover

            if let cover = metadata.cover {
                let data = Data(base64Encoded: cover)
                let imageId = UUID().uuidString

                let imagePath = booksFolder.appending(path: "\(bookId)/\(imageId)")

                try? data?.write(to: imagePath)

                metadata.cover = "books/\(bookId)/\(imageId)"
            }

            let parsedMetadata = BookMetadata(
                title: metadata.title ?? "Unknown Title",
                author: metadata.author,
                description: metadata.description,
                subject: metadata.subject,
                bookPath: "books/\(bookId)/\(documentsBook.lastPathComponent)",
                bookCover: metadata.cover
            )

            url.stopAccessingSecurityScopedResource()
            return parsedMetadata
        } catch {
            // if fail remove book file from docuemnts
            print("Failed to extract metadata from book: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: documentsBook)
            return nil
        }
    }

    public func getPDFMetadata(from url: URL) async -> BookMetadata? {
        guard url.pathExtension == "pdf" else {
            return nil
        }

        _ = url.startAccessingSecurityScopedResource()
        let bookId = UUID()

        guard let documentsBook = copyBook(from: url, id: bookId) else {
            url.stopAccessingSecurityScopedResource()
            return nil
        }

        let document = PDFDocument(url: documentsBook)
        let pdfMetadata = document?.documentAttributes
        let author = (
            pdfMetadata?[PDFDocumentAttribute.authorAttribute] ?? pdfMetadata?["Author"]
        ) as? String ?? "Unknown Author"
        let title = pdfMetadata?[PDFDocumentAttribute.titleAttribute] as? String ?? "Unknown Title"
        let description = pdfMetadata?[PDFDocumentAttribute.subjectAttribute] as? String

        let metadataAuthor = MetadataAuthor(name: author)
        let coverPath = getPDFCoverPath(from: documentsBook, with: bookId)

        let metadata = BookMetadata(
            title: title,
            author: [metadataAuthor],
            description: description,
            bookPath: "books/\(bookId)/\(documentsBook.lastPathComponent)",
            bookCover: coverPath
        )

        url.stopAccessingSecurityScopedResource()
        return metadata
    }

    /// copies book from url to documents dir with path being 'documents/{saveFolderName}/{lastPathComponent}'
    public func copyBook(from url: URL, id bookId: UUID) -> URL? {
        let path = booksFolder.appending(
            path: "\(bookId)",
            directoryHint: .isDirectory
        )

        let destination = path.appending(
            path: url.lastPathComponent,
            directoryHint: .notDirectory
        )

        try? FileManager.default.createDirectory(
            at: path,
            withIntermediateDirectories: true
        )
        try? FileManager.default.copyItem(
            at: url,
            to: destination
        )

        if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) == true {
            return destination
        }

        return nil
    }

    private func getPDFCoverPath(from pdfUrl: URL, with bookId: UUID) -> String? {
        let coverImage = pdfToImage(from: pdfUrl, at: 1)

        if let pngData = coverImage?.pngData() {
            let imageId = "\(UUID().uuidString).png"

            let base = "books/\(bookId)/\(imageId)"
            let imagePath = URL.documentsDirectory.appending(path: base)

            try? pngData.write(to: imagePath)

            return base
        }

        return nil
    }
}

func pdfToImage(from url: URL, at page: Int) -> UIImage? {
    guard let document = CGPDFDocument(url as CFURL) else { return nil }

    guard let page = document.page(at: page) else { return nil }

    let pageRect = page.getBoxRect(.mediaBox)

    let cropRect = pageRect

    let renderer = UIGraphicsImageRenderer(size: cropRect.size)
    let img = renderer.image { ctx in
        // Set the background color.
        UIColor.white.set()
        ctx.fill(CGRect(x: 0, y: 0, width: cropRect.width, height: cropRect.height))

        // Translate the context so that we only draw the `cropRect`.
        ctx.cgContext.translateBy(x: -cropRect.origin.x, y: pageRect.size.height - cropRect.origin.y)

        // Flip the context vertically because the Core Graphics coordinate system starts from the bottom.
        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

        // Draw the PDF page.
        ctx.cgContext.drawPDFPage(page)
    }

    return img
}
