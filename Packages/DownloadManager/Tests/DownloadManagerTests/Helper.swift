//
//  File.swift
//
//
//  Created by Mirna Olvera on 4/10/24.
//

import Combine
@testable import DownloadManager
import Foundation
import XCTest

// https://jacobbartlett.substack.com/p/unit-test-the-observation-framework
extension XCTestCase {
    /// Waits for changes to a property at a given key path of an `@Observable` entity.
    ///
    /// Uses the Observation framework's global `withObservationTracking` function to track changes to a specific property.
    /// By using wildcard assignment (`_ = ...`), we 'touch' the property without wasting CPU cycles.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property to observe.
    ///   - parent: The observable view model that contains the property.
    ///   - timeout: The time (in seconds) to wait for changes before timing out. Defaults to `1.0`.
    ///
    func waitForChanges<T, U>(to keyPath: KeyPath<T, U>, on parent: T, timeout: Double = 1.0) {
        let exp = expectation(description: #function)
        withObservationTracking {
            _ = parent[keyPath: keyPath]
        } onChange: {
            exp.fulfill()
        }

        waitForExpectations(timeout: timeout)
    }
}

extension DownloadManager {
    func makeDownload(for url: URL) -> Download {
        let download = Download(
            id: UUID().uuidString,
            url: url,
            progress: .init()
        )

        return download
    }

    func append(_ url: URL) -> Download {
        let download = makeDownload(for: url)
        append(download)
        return download
    }
}

@Observable
public class Downloader {
    public static let shared = Downloader()
    public var manager = DownloadManager()

    @ObservationIgnored
    private var subscriptions = Set<AnyCancellable>()

    var requestedURLs = [URL]()
    var tasks = [Download.ID: URLSessionDownloadTask]()

    init() {
        manager.onDidCreateTask
            .sink { [weak self] id, task in

                guard let self = self else {
                    return
                }

                tasks.updateValue(task, forKey: id)
                let download = manager.downloadQueue.cache[id]
                if let url = download?.url {
                    requestedURLs.append(url)
                }
            }
            .store(in: &subscriptions)
    }
}

extension URLSessionTask.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .canceling:
            return "canceling"
        case .running:
            return "running"
        case .suspended:
            return "suspended"
        case .completed:
            return "completed"
        @unknown default:
            return "unknown"
        }
    }
}
