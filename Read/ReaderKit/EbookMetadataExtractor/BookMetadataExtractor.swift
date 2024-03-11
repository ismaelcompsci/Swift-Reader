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

class BookMetadataExtractor {
    static let shared = BookMetadataExtractor()

    let extracterInstance: Int = 0

    init() {}

    /**
     TODO: remove the instance of meatadataextractore after its done to save memeory
     */
    func getMetadata(path bookPath: String, completion: @escaping (Result<BookMetadata, BookMetadataError>) -> Void) {
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

    func parseBook(from url: URL, completion: @escaping (Result<BookMetadata, BookMetadataError>) -> Void) {
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
                print("[BookMetadataExtractor] parseBook: \(error.localizedDescription)")
                return completion(.failure(.fileError))
            }

            var bookMetadata = BookMetadata()

            if isPdf {
                let optionalTitle = destinationBookURL.deletingPathExtension().lastPathComponent
                let document = PDFDocument(url: destinationBookURL)
                let metadata = document?.documentAttributes!

                let author = metadata?[PDFDocumentAttribute.authorAttribute] ?? metadata?["Author"] ?? "Unknown Author"
                let title = metadata?[PDFDocumentAttribute.titleAttribute] ?? (optionalTitle != "" ? optionalTitle : "Unknown Title")
                let description = metadata?[PDFDocumentAttribute.subjectAttribute]

                var coverImage: UIImage?
                if let cover = getPDFCover(ofPDFAt: destinationBookURL) {
                    coverImage = cover
                } else {
                    // https://pspdfkit.com/blog/2020/convert-pdf-to-image-in-swift/
                    if let page = document?.page(at: 0)?.pageRef {
                        // Fetch the page rect for the page we want to render.
                        let pageRect = page.getBoxRect(.mediaBox)

                        let cropRect = pageRect

                        let renderer = UIGraphicsImageRenderer(size: cropRect.size)
                        coverImage = renderer.image { ctx in
                            // Set the background color.
                            UIColor.black.set()
                            ctx.fill(CGRect(x: 0, y: 0, width: cropRect.width, height: cropRect.height))

                            // Translate the context so that we only draw the `cropRect`.
                            ctx.cgContext.translateBy(x: -cropRect.origin.x, y: pageRect.size.height - cropRect.origin.y)

                            // Flip the context vertically because the Core Graphics coordinate system starts from the bottom.
                            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

                            // Draw the PDF page.
                            ctx.cgContext.drawPDFPage(page)
                        }
                    }
                }

                let fullAuthor = MetadataAuthor(name: String(describing: author))

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
                        print("[BookMetadataExtractor] parseBook: Failed to write image, \(error.localizedDescription)")
                        return completion(.failure(.fileError))
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
                                print("[BookMetadataExtractor] parseBook: Failed to write image, \(error.localizedDescription)")
                                return completion(.failure(.fileError))
                            }
                        }

                        completion(.success(bookMetadata))

                    case .failure(let failure):
                        print("[BookMetadataExtractor] parseBook: \(failure)")
                        return completion(.failure(.metadataExtractionError))
                    }

                    do {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
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

    // async version
    // the callback version caused issues when importin a large amount of files
    func parseBook(from url: URL) async throws -> BookMetadata {
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<BookMetadata, Error>) in

            self.parseBook(from: url) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }
}
