//
//  DownloadQueue.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import Combine
import Foundation

@Observable
class DownloadQueue {
    var cache = [Download.ID: Download]()
    private(set) var downloads = [Download]()

    @ObservationIgnored
    var onShouldDownload = PassthroughSubject<Download, Never>()
    @ObservationIgnored
    var onQueueChange = PassthroughSubject<Void, Never>()

    var maxConcurrentDownloads: Int = 3 {
        didSet {
            update()
        }
    }

    func update() {
        let downloadsByStatus = Dictionary(grouping: downloads, by: { $0.status })
        let numberDownloading = downloadsByStatus[.downloading]?.count ?? 0
        let slotsAvailable = maxConcurrentDownloads - numberDownloading

        guard numberDownloading <= maxConcurrentDownloads else {
            return
        }

        for download in downloadsByStatus[.idle]?.prefix(slotsAvailable) ?? [] {
            onShouldDownload.send(download)
        }
    }

    func download(with id: Download.ID) -> Download? {
        cache[id]
    }

    private func add(_ download: Download) {
        downloads.append(download)
        cache[download.id] = download
    }

    func append(_ download: Download) {
        add(download)

        update()

        onQueueChange.send()
    }

    func remove(_ download: Download) {
        cache.removeValue(forKey: download.id)

        downloads.removeAll(where: { $0.id == download.id })

        update()

        onQueueChange.send()
    }
}
