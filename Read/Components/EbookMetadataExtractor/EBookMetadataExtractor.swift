//
//  EbookMetadataExtractor.swift
//  Read
//
//  Created by Mirna Olvera on 2/1/24.
//

import Foundation
import PDFKit

enum BookMetadataError: Error {
    case decodingError
    case metadataExtractionError
    case fileError
}

class EBookMetadataExtractor {
    static let extracterInstance: Int = 0

    init() {}

    /**
     TODO: remove the instance of meatadataextractore after its done to save memeory
     */
    static func getMetadata(path bookPath: String, completion: @escaping (Result<BookMetadata, BookMetadataError>) -> Void) {
        let extracterName = "metadata\(extracterInstance)"
        let function = """
        var \(extracterName) = new MetaDataExtractor()
        var promise = \(extracterName)?.initBook(`\(bookPath)`);
        await promise;
        return promise;
        """

        HeadlessWebView.shared.webView.callAsyncJavaScript(function, in: nil, in: .page) { result in
            switch result {
            case .success(let metadata):
                let metadataString = String(describing: metadata)
                if let data = metadataString.data(using: .utf8) {
                    do {
                        let book = try JSONDecoder().decode(BookMetadata.self, from: data)
                        completion(.success(book))
                    } catch {
                        print("Failed to decode")
                        completion(.failure(.decodingError))
                    }
                } else {
                    print("NO DATA")
                    completion(.failure(.decodingError))
                }

            case .failure(let error):
                print("[JS_SWIFT] initBook \(error.localizedDescription)")
                completion(.failure(.metadataExtractionError))
            }
        }
    }

    static func parseBook(from url: URL, completion: @escaping (Result<BookMetadata, BookMetadataError>) -> Void) {
        let accessing = url.startAccessingSecurityScopedResource()
        let isPdf = url.lastPathComponent.hasSuffix(".pdf")

        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let id = UUID()
            let bookDirectoryString = "\(id)"
            let lastPathComponent = "\(url.lastPathComponent)"

            let destinationDirectoryURL = documentsDirectory.appending(path: bookDirectoryString, directoryHint: .isDirectory)
            let destinationBookURL = destinationDirectoryURL.appending(path: lastPathComponent, directoryHint: .notDirectory)

            do {
                try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: false)

                try FileManager.default.copyItem(at: url, to: destinationBookURL)
            } catch {
                print("File: \(error.localizedDescription)")
                return completion(.failure(.fileError))
            }

            var bookMetadata = BookMetadata()

            if isPdf {
                let document = PDFDocument(url: destinationBookURL)
                let metadata = document?.documentAttributes!

                let author = metadata?[PDFDocumentAttribute.authorAttribute] ?? metadata?["Author"] ?? "Unknown Author"
                let title = metadata?[PDFDocumentAttribute.titleAttribute]
                let description = metadata?[PDFDocumentAttribute.subjectAttribute]

                let coverImage = getPDFCover(ofPDFAt: destinationBookURL)

                let fullAuthor = Author(name: String(describing: author))

                bookMetadata.title = title as! String? ?? "Unknown Title"
                bookMetadata.description = description as! String? ?? ""
                bookMetadata.author?.append(fullAuthor)
                bookMetadata.bookPath = "\(bookDirectoryString)/\(lastPathComponent)"

                if let coverData = coverImage?.pngData() {
                    let lastImagePathComponent = "\(UUID()).png"
                    let imagePath = destinationDirectoryURL.appending(path: lastImagePathComponent)

                    do {
                        try coverData.write(to: imagePath)
                        bookMetadata.bookCover = "\(bookDirectoryString)/\(lastImagePathComponent)"

                    } catch {
                        print("Failed to write image, \(error.localizedDescription)")
                    }
                }

                return completion(.success(bookMetadata))

            } else {
                self.getMetadata(path: destinationBookURL.absoluteString) { result in
                    switch result {
                    case .success(let newBookMetadata):

                        bookMetadata.title = newBookMetadata.title ?? "Unknown Title"
                        bookMetadata.description = newBookMetadata.description
                        bookMetadata.bookPath = "\(bookDirectoryString)/\(lastPathComponent)"
                        bookMetadata.author = newBookMetadata.author
                        bookMetadata.subject = newBookMetadata.subject

                        // write cover to file
                        if let cover = newBookMetadata.cover {
                            let data = Data(base64Encoded: cover)
                            let lastImagePathComponent = "\(UUID())\(getImageType(base64: String(cover.prefix(20))) ?? "-default.png")"
                            let imagePath = destinationDirectoryURL.appending(path: lastImagePathComponent)

                            do {
                                try data?.write(to: imagePath)
                                bookMetadata.bookCover = "\(bookDirectoryString)/\(lastImagePathComponent)"

                            } catch {
                                print("Failed to write image, \(error.localizedDescription)")
                            }
                        }

                        completion(.success(bookMetadata))

                    case .failure(let failure):
                        print("Could not parse book: \(failure)")
                    }
                }
            }
        }

        do {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
