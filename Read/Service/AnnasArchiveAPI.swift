//
//  AnnasArchiveAPI.swift
//  Read
//
//  Created by Mirna Olvera on 2/24/24.
//
import Foundation
import SwiftSoup

let annasArchiveURL = "https://annas-archive.org"
let annasArchiveURLAlternative1 = "https://annas-archive.gs"
let annasArchiveURLAlternative2 = "https://annas-archive.se"

struct SearchResult: Identifiable {
    var id: String
    var title: String
    var thumbnail: String?
    var author: String?
    var publisher: String?
    var info: String?
}

enum FileType: String {
    case pdf
    case epub
    case mobi
    case fb2
    case cbz
    case azw3
}

enum ParamType: String {
    case Content = "content"
    case FileExt = "ext"
    case Access = "acc"
    case Source = "src"
    case Sort = "sort"
    case Languague = "lang"
}

enum Access: String {
    case PartnerServerDownload = "aa_download"
    case ExternalDownload = "external_download"
    case ExternalBorrow = "external_borrow"
    case ExternalBorrowPrintDisabled = "external_borrow_printdisabled"
}

enum Source: String {
    case Libgen = "lgli"
    case ZLibrary = "zlib"
    case LibgenRS = "lgrs"
    case InternetArchive = "ia"
    case SciHub = "scihub"
}

enum Sort: String {
    case MostRelevant = ""
    case Newest = "newest" // pub year
    case Oldest = "oldest" // pub year
    case Largest = "largest" // filesize
    case Smallest = "smallest" // filesize
}

enum Languague: String {
    case English = "en"
    case Unknown = "_empty"
    case Spanish = "es"
    case French = "fr"
    case German = "de"
    case Russian = "ru"
    case Chinese = "zh"
    case Italian = "it"
    case Dutch = "nl"
    case Portuguese = "pt"
    case Irish = "ga"
    case Latin = "la"
    case Japanese = "ja"
    case Indonesian = "id"
    case Arabic = "ar"
    case Greek = "el"
    case Turkish = "tr"
    case Hebrew = "he"
    case Hindi = "hi"
    case Korean = "ko"
    case Vietnamese = "vi"
    case Polish = "pl"
    case Hungarian = "hu"
    case Luxembourgish = "lb"
    case Persian = "fa"
    case Danish = "da"
    case Swedish = "sv"
    case Czech = "cs"
    case Ndolo = "ndl"
    case Bulgarian = "bg"
    case Afrikaans = "af"
    case Ukrainian = "uk"
    case Bangla = "bn"
    case Romanian = "ro"
    case Urdu = "ur"
    case Norwegian = "no"
    case Croatian = "hr"
    case Welsh = "cy"
}

enum ContentType: String {
    case BookNonFiction = "book_nonfiction"
    case BookFiction = "book_fiction"
    case BookUnknown = "book_unknown"
    case ComicBook = "book_comic"
    case Magazine = "magazine"
    case StandardsDocument = "standards_document"
}

class AnnasArchiveAPI {
    static let shared = AnnasArchiveAPI()
    let baseURL = URL(string: annasArchiveURL)

    init() {}

    func buildURLQueryParams(for url: URL, query: String, fileType: [FileType]? = nil, access: [Access]? = nil, source: [Source]? = nil, orderBy: Sort? = nil, language: [Languague]? = nil) -> URL {
        var queryItems = [URLQueryItem]()

        fileType?.forEach { type in
            queryItems.append(URLQueryItem(name: ParamType.FileExt.rawValue, value: type.rawValue))
        }

        access?.forEach { access in
            queryItems.append(URLQueryItem(name: ParamType.Access.rawValue, value: access.rawValue))
        }

        source?.forEach { src in
            queryItems.append(URLQueryItem(name: ParamType.Source.rawValue, value: src.rawValue))
        }

        language?.forEach { lang in
            queryItems.append(URLQueryItem(name: ParamType.Languague.rawValue, value: lang.rawValue))
        }

        queryItems.append(URLQueryItem(name: ParamType.Sort.rawValue, value: orderBy?.rawValue))

        queryItems.append(URLQueryItem(name: "q", value: query))

        return url.appending(queryItems: queryItems)
    }

    func fetchHTML(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "HTTP Error", code: 0, userInfo: nil)))
                return
            }

            if let data = data, let htmlString = String(data: data, encoding: .utf8) {
                completion(.success(htmlString))
            } else {
                completion(.failure(NSError(domain: "Invalid Data", code: 0, userInfo: nil)))
            }
        }

        task.resume()
    }

    func fetchHTML(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<String, Error>) in
            fetchHTML(url: url) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }

    func extractFileInfo(info: String) -> AnnasArchiveBookInfo? {
        // https://github.com/dheison0/annas-archive-api/blob/368d71d9e2000a9e9956282585a6a012848a9011/api/extractors/generic.py#L4

        var splitInfo = info.split(separator: ",")
        var language: String?

        if splitInfo[0] == "[" {
            if let last = splitInfo.popLast() {
                language = String(describing: last)
            }
        }

        let ext = splitInfo.popLast()

        let size = splitInfo.popLast()

        guard let ext, let size else {
            return nil
        }

        return AnnasArchiveBookInfo(language: language, ext: String(ext), size: String(size))
    }
}

extension AnnasArchiveAPI {
    func searchBooks(query: String, fileType: [FileType]? = nil, access: [Access]? = nil, source: [Source]? = nil, orderBy: Sort? = nil, language: [Languague]? = nil) async -> [SearchResult] {
        guard var searchUrl = baseURL?.appending(path: "search") else {
            return []
        }

        searchUrl = buildURLQueryParams(for: searchUrl, query: query, fileType: fileType, access: access, source: source, orderBy: orderBy, language: language)

        do {
            var html = try await fetchHTML(url: searchUrl)

            // html comes with commented out books that are partial matches
            html.replace("<!--", with: "")
            html.replace("-->", with: "")

            // parse html
            let document = try SwiftSoup.parse(html)
            let elements = try document.select("a").addClass("js-vim-focus")

            var searchResults = [SearchResult]()

            for element in elements {
                let title = try element.getElementsByTag("h3").first()?.text()
                let thumbnail = try element.getElementsByTag("img").first()?.attr("src")
                let id = try element.attr("href").split(separator: "/md5/").last

                let author = try element.select("""
                div[class="max-lg:line-clamp-[2] lg:truncate leading-[1.2] lg:leading-[1.35] max-lg:text-sm italic"]
                """).first()?.text() ?? "Unknown Author"

                let publisher = try element.select("""
                div[class="truncate leading-[1.2] lg:leading-[1.35] max-lg:text-xs"]
                """).first()?.text()

                let info = try element.select("""
                div[class="line-clamp-[2] leading-[1.2] text-[10px] lg:text-xs text-gray-500"]
                """).first()?.text()

                guard let id, let info, let title else {
                    continue
                }

                let bookMD5 = String(id)
                let book = SearchResult(id: bookMD5, title: title, thumbnail: thumbnail, author: author, publisher: publisher, info: info)

                searchResults.append(book)
            }

            return searchResults

        } catch {
            print("[AnnasArchiveAPI] searchBooks: \(error.localizedDescription)")
            return []
        }
    }

    func getBookInfo(id md5: String) async -> AnnasArchiveBook? {
        // build url
        guard let bookURL = baseURL?.appending(path: "/md5/\(md5)") else {
            return nil
        }

        do {
            var html = try await fetchHTML(url: bookURL)

            html.replace("<!--", with: "")
            html.replace("-->", with: "")

            let document = try SwiftSoup.parse(html)

            let title = try document.select("""
            div[class="text-3xl font-bold"]
            """).first()?.text().replacing("🔍", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

            let authors = try document.select("""
            div[class="italic"]
            """).first()?.text().replacing("🔍", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

            let description = try document.select("""
            div[class="mt-4 line-clamp-[5] js-md5-top-box-description"]
            """).first()?.text()

            let thumbnail = try document.select("img").attr("src")

            let publishInfo = try document.select("""
            div[class="text-md"]
            """).first()?.text()

            let rawFileInfo = try document.select("""
            div[class="text-sm text-gray-500"]
            """).first()?.text()

            var fileInfo: AnnasArchiveBookInfo?

            if let rawFileInfo {
                fileInfo = extractFileInfo(info: rawFileInfo)
            }

            var downloadLinks = [String]()

            for element in try document.select("""
            a[class="js-download-link"]
            """) {
                let link = try element.attr("href")

                if link == "/datasets" {
                    continue
                }

                if link.first != "/" {
                    continue
                }

                downloadLinks.append(link)
            }

            return AnnasArchiveBook(title: title ?? "Unknown Title", description: description ?? "", authors: authors ?? "Unknown Author", file_info: fileInfo, downloadURLS: downloadLinks, thumbnail: thumbnail, publishInfo: publishInfo)

        } catch {
            print("Failed to get bookInfo: \(error.localizedDescription)")
        }

        return nil
    }
}

struct AnnasArchiveBookInfo {
    var language: String?
    var ext: String
    var size: String
}

struct AnnasArchiveBook {
    var title: String
    var description: String
    var authors: String
    var file_info: AnnasArchiveBookInfo?
    var downloadURLS: [String]
    var thumbnail: String?
    var publishInfo: String?
}
