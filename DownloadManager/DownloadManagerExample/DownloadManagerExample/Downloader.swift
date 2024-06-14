//
//  Downloader.swift
//  DownloadManagerExample
//
//  Created by Mirna Olvera on 4/11/24.
//

import Combine
import DownloadManager
import Foundation

@Observable
class Downloader {
    var manager = DownloadManager()
    var queue = [Download]()

    @ObservationIgnored
    var subscriptions = Set<AnyCancellable>()

    init() {
//        manager.onDownloadFinished
//            .sink { [weak self] download, _ in
//                print("DOWNLOAD FINISHED")
//                self?.manager.remove(download)

//                if let index = self?.queue.firstIndex(where: { $0.id == d.id }) {
//                    self?.queue.remove(at: index)
//                }
//            }
//            .store(in: &subscriptions)

        manager.onQueueDidChange
            .sink { [weak self] downloads in
                self?.queue = downloads
                print(downloads.count)
            }
            .store(in: &subscriptions)
    }

    func download(url: URL) {
        manager.append(.init(id: UUID().uuidString, url: url, progress: .init()))
    }
}
