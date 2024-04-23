//
//  BookDownloader.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import Combine
import DownloadManager
import Foundation
import UIKit

@Observable
public class BookDownloader {
    public static let shared = BookDownloader()
    var manager: DownloadManager

    var queue = [Download]()
    var bookInfo = [Download.ID: BookInfo]()
    private var resumeData = [Download.ID: Data]()

    @ObservationIgnored
    private var subscriptions = Set<AnyCancellable>()

    func download(with id: String, for url: URL) {
        let download = Download(id: id, url: url, progress: .init())

        manager.append(download)
    }

    func pause(_ download: Download) {
        manager.pause(download)
    }

    func resume(_ download: Download) {
        manager.resume(download)
    }

    func cancel(_ download: Download) {
        manager.remove(download)
    }

    func resumeDataForDownload(_ download: Download) -> Data? {
        return resumeData.removeValue(forKey: download.id)
    }

    init() {
        manager = DownloadManager()
        manager.resumeDataForDownload = resumeDataForDownload

        manager.onQueueDidChange.sink { [weak self] downloads in
            guard let self = self else { return }
            Log("DownloadManger queue did change")
            self.queue = downloads
        }
        .store(in: &subscriptions)

        manager.onDownloadFinished.sink { [weak self] download, location in
            guard let self = self else { return }
            self.downloadFinished((download, location))
        }
        .store(in: &subscriptions)

        manager.onDidCancelWithResumeData.sink { [weak self] download, data in
            guard let self = self else { return }

            switch download.status {
                case .failed(let error):
                    Toaster.shared.presentToast(
                        message: "Failed to download \(error.localizedDescription)",
                        type: .error
                    )

                    self.cancel(download)

                default:
                    break
            }

            if let data = data {
                self.resumeData.updateValue(data, forKey: download.id)
            }
        }
        .store(in: &subscriptions)

        #if DEBUG
        manager.maxConcurrentDownloads = 1
        #else
        manager.maxConcurrentDownloads = 3
        #endif

        NotificationCenter.default.publisher(
            for: UIApplication.didReceiveMemoryWarningNotification
        )
        .sink { [weak self] _ in
            guard let self = self else { return }
            self.resumeData.removeAll()
        }
        .store(in: &subscriptions)
    }
}

extension BookDownloader {
    func downloadFinished(_ finished: DownloadManager.OnDownloadFinished) {
        let (download, location) = finished

        let info = bookInfo[download.id]
        let bookTitle = "\(info?.title ?? "book")"

        Log("DOWNLOAD FINISHDED: \(info?.title ?? download.id)")

        Task {
            if download.status != .finished { return }

            do {
                if let info = info {
                    try await BookManager.shared.process(for: location, with: info)

                } else {
                    try await BookManager.shared.process(for: location)
                }

                Toaster.shared.presentToast(
                    message: "Added \(bookTitle) to library.",
                    type: .message
                )

                cancel(download)
                queue.removeAll(where: { $0.id == download.id })
                bookInfo.removeValue(forKey: download.id)
            } catch {
                Log("Failed to import book: \(error.localizedDescription)")
                Toaster.shared.presentToast(message: "Failed to add \(bookTitle) to library", type: .error)
            }
        }
    }
}

extension BookDownloader {
    static func clearDownloadFolder() {
        let downloadFolderPath = DownloadManager.downloadsPath

        try? FileManager.default.removeItem(at: downloadFolderPath)
        try? FileManager.default.createDirectory(at: downloadFolderPath, withIntermediateDirectories: true)
    }

    static func getDownloadFolderSize() -> UInt64 {
        let downloadFolderPath = DownloadManager.downloadsPath

        return FileManager.default.allocatedSizeOfDirectory(at: downloadFolderPath)
    }
}
