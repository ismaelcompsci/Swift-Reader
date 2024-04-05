//
//  BookDownloader.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import Combine
import Foundation

@Observable
class BookDownloader {
    var manager = DownloadManager()

    @ObservationIgnored
    private var subscriptions = Set<AnyCancellable>()

    var queue = [Download]()

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

    init() {
        manager.onQueueDidChange.sink { [weak self] downloads in
            guard let strongSelf = self else { return }

            strongSelf.queue = downloads
        }
        .store(in: &subscriptions)

//        manager.onDownloadFinished.sink { [weak self] download, _ in
//            guard let self = self else { return }
//            self.manager.remove(download)
//        }
//        .store(in: &subscriptions)
    }
}
