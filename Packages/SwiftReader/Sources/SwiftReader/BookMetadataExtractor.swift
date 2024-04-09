//
//  EbookMetadataExtractor.swift
//  Read
//
//  Created by Mirna Olvera on 2/1/24.
//

import Foundation
import PDFKit

public enum BookMetadataError: Error {
    case decodingError
    case metadataExtractionError
    case fileError
}

public class BookMetadataExtractor {
    public static let shared = BookMetadataExtractor()
    
    public static let saveFolderName = "books"
    public static let basePath = URL.documentsDirectory
    
    let extracterInstance: Int = 0
    
    init() {
        try? FileManager.default.createDirectory(at: Self.basePath, withIntermediateDirectories: true)
    }
    
    private func getMetadata(path bookPath: String, completion: @escaping (Result<BookMetadata, BookMetadataError>) -> Void) {
        let extracterName = "metadata\(extracterInstance)"
        let function = """
        var \(extracterName) = new MetaDataExtractor()
        var promise = \(extracterName)?.initBook(`\(bookPath)`);
        await promise;
        return promise;
        """
        DispatchQueue.main.async {
            HeadlessWebView.shared.webView.callAsyncJavaScript(function, in: nil, in: .page) { result in
                switch result {
                case .success(let metadata):
                    let metadataString = String(describing: metadata)
                    if let data = metadataString.data(using: .utf8) {
                        do {
                            let book = try JSONDecoder().decode(BookMetadata.self, from: data)
                            completion(.success(book))
                        } catch {
                            print("[BookMetadataExtractor] getMetadata: Failed to decode - \(error.localizedDescription)")
                            completion(.failure(.decodingError))
                        }
                    } else {
                        print("[BookMetadataExtractor] getMetadata: NO DATA")
                        completion(.failure(.decodingError))
                    }
                    
                case .failure(let error):
                    print("[BookMetadataExtractor] getMetadata: \(error.localizedDescription)")
                    completion(.failure(.metadataExtractionError))
                }
            }
        }
    }

    /// copies book from url to documents dir with path being 'documents/{saveFolderName}/{lastPathComponent}'
    public func copyBook(from url: URL, id bookId: UUID) -> URL? {
        let path = Self.basePath.appending(
            path: makeBookBasePath(
                bookId: bookId.uuidString
            ),
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
        
        var coverPath: String?
        
        if let pngData = coverImage?.pngData() {
            let imageId = "\(UUID().uuidString).png"
            
            let base = makeBookBasePath(bookId: bookId.uuidString)
            let documentsBase = URL.documentsDirectory.appending(path: base)
            
            let imagePath = documentsBase.appending(path: imageId)
            
            try? pngData.write(to: imagePath)
            coverPath = "\(base)/\(imageId)"
            
            return coverPath
        }
        
        return nil
    }
    
    public func makeBookBasePath(bookId: String) -> String {
        return "\(Self.saveFolderName)/\(bookId)"
    }
    
    public func parsePDF(from url: URL) -> BookMetadata? {
        // parse metadata
        _ = url.startAccessingSecurityScopedResource()
        
        let bookId = UUID()
        
        guard let newPath = copyBook(from: url, id: bookId) else {
            url.stopAccessingSecurityScopedResource()
            return nil
        }
        
        let document = PDFDocument(url: newPath)
        let pdfMetadata = document?.documentAttributes
        let author = (
            pdfMetadata?[PDFDocumentAttribute.authorAttribute] ?? pdfMetadata?["Author"]
        ) as? String ?? "Unknown Author"
        let title = pdfMetadata?[PDFDocumentAttribute.titleAttribute] as? String ?? "Unknown Title"
        let description = pdfMetadata?[PDFDocumentAttribute.subjectAttribute] as? String
        
        let metadataAuthor = MetadataAuthor(name: author)
        let coverPath = getPDFCoverPath(from: newPath, with: bookId)
        
        let metadata = BookMetadata(
            title: title,
            author: [metadataAuthor],
            description: description,
            bookPath: "\(makeBookBasePath(bookId: bookId.uuidString))/\(url.lastPathComponent)",
            bookCover: coverPath
        )
        
        url.stopAccessingSecurityScopedResource()
        return metadata
    }
    
    public func parseEBook(from url: URL) async -> BookMetadata? {
        _ = url.startAccessingSecurityScopedResource()
        let bookId = UUID()
        
        guard let newPath = copyBook(from: url, id: bookId) else {
            url.stopAccessingSecurityScopedResource()
            return nil
        }
        
        guard let metadata = try? await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<BookMetadata, Error>) in
            getMetadata(path: newPath.absoluteString) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }) else {
            url.stopAccessingSecurityScopedResource()
            return nil
        }
        
        var coverPath: String?
        
        if let cover = metadata.cover {
            let data = Data(base64Encoded: cover)
            let imageId = UUID().uuidString
            let imageType = getImageType(base64: String(cover.prefix(20))) ?? "-default.png"
            
            let base = makeBookBasePath(bookId: bookId.uuidString)
            let filename = "\(base)/\(imageId)\(imageType)"
            
            let newImagePath = URL.documentsDirectory.appending(path: filename)
            try? data?.write(to: newImagePath)
            
            coverPath = filename
        }
        
        let parsedMetadata = BookMetadata(
            title: metadata.title ?? "Unknown Title",
            author: metadata.author,
            description: metadata.description,
            subject: metadata.subject,
            bookPath: "\(makeBookBasePath(bookId: bookId.uuidString))/\(newPath.lastPathComponent)",
            bookCover: coverPath
        )
        
        url.stopAccessingSecurityScopedResource()
        return parsedMetadata
    }

    /// file is saved to 'documents/{uuid}/{lastPathComponent}' in documents directory
    /// cover image is saved to documents/{uuid}/{uuid}.png
}
