//
//  DownloadManager.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import Combine
import Foundation

@Observable
class DownloadManager: NSObject {
    public typealias OnDownloadFinished = (Download, URL)

    private var session: URLSession!
    var downloadQueue = DownloadQueue()

    private var tasks = [Download.ID: URLSessionDownloadTask]()
    private var taskIdentifiers = [Int: Download]()

    @ObservationIgnored
    private var subscription = Set<AnyCancellable>()
    @ObservationIgnored
    private(set) var onQueueDidChange = PassthroughSubject<[Download], Never>()
    @ObservationIgnored
    private(set) var onDownloadFinished = PassthroughSubject<OnDownloadFinished, Never>()

    override init() {
        super.init()

        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())

        downloadQueue.onShouldDownload
            .sink { [weak self] download in
                self?.tasks[download.id]?.resume()
                download.status = .downloading
            }
            .store(in: &subscription)

        downloadQueue.onQueueChange.sink { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.onQueueDidChange.send(strongSelf.downloadQueue.downloads)
        }
        .store(in: &subscription)
    }

    func download(with id: Download.ID) -> Download? {
        downloadQueue.download(with: id)
    }

    func append(_ download: Download) {
        let task = createTask(for: download)
        tasks[download.id] = task

        DispatchQueue.main.async {
            self.downloadQueue.append(download)
        }
    }

    func pause(_ download: Download) {
        guard download.status != .finished else { return }
        download.status = .paused
        cancelTask(for: download)
    }

    func resume(_ download: Download) {
        guard download.status != .finished else { return }

        let task = createTask(for: download)

        tasks.updateValue(task, forKey: download.id)

        download.status = .idle
    }

    private func createTask(for download: Download) -> URLSessionDownloadTask {
        let task = session.downloadTask(with: download.request)
        taskIdentifiers[task.taskIdentifier] = download
        return task
    }

    private func cancelTask(for download: Download) {
        guard let task = tasks[download.id] else {
            return
        }

        task.cancel { [weak self] _ in
            DispatchQueue.main.async {
//                (download, didCancelWithResumeData: data)
                self?.tasks.removeValue(forKey: download.id)
                self?.taskIdentifiers.removeValue(forKey: task.taskIdentifier)
            }
        }
    }

    func remove(_ download: Download) {
        cancelTask(for: download)
        downloadQueue.remove(download)
    }
}

extension DownloadManager {
    static let downloadsPath = URL.documentsDirectory.appending(path: "Downloads")

    func moveFileToDownloadsFolder(at location: URL, download: Download, recommendedName: String?) -> URL {
        try? FileManager.default.createDirectory(at: Self.downloadsPath, withIntermediateDirectories: false)

        // unique filename
        // https://github.com/mozilla-mobile/firefox-ios/blob/8e0a9152c635fa59f7b7c9bfc229093c365f6f04/firefox-ios/Client/Frontend/Browser/DownloadQueue.swift#L38
        let filename = recommendedName ?? download.id
        let basePath = Self.downloadsPath.appending(path: filename)
        let fileExtension = basePath.pathExtension
        let filenameWithoutExtension = !fileExtension.isEmpty ? String(filename.dropLast(fileExtension.count + 1)) : filename

        var proposedPath = basePath
        var count = 0

        while FileManager.default.fileExists(atPath: proposedPath.path) {
            count += 1

            let proposedFilenameWithoutExtension = "\(filenameWithoutExtension) (\(count))"
            proposedPath = Self.downloadsPath
                .appendingPathComponent(proposedFilenameWithoutExtension)
                .appendingPathExtension(fileExtension)
        }
        //

        try? FileManager.default.moveItem(at: location, to: proposedPath)
        return proposedPath
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let download = taskIdentifiers[downloadTask.taskIdentifier] else {
            return
        }

        let newDestination = moveFileToDownloadsFolder(
            at: location,
            download: download,
            recommendedName: downloadTask.response?.suggestedFilename
        )

        DispatchQueue.main.async {
            guard let httpResponse = downloadTask.response as? HTTPURLResponse,
                  Set(200 ... 299).contains(httpResponse.statusCode)
            else {
                return
            }

            self.onDownloadFinished.send((download, newDestination))
            download.status = .finished
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            guard let download = self.taskIdentifiers[task.taskIdentifier] else {
                return
            }

            if let error = error as NSError? {
                if error.domain == NSURLErrorDomain {
                    let urlError = URLError(URLError.Code(rawValue: error.code))
                    // Don't consider cancellation a failure.
                    if urlError.code != .cancelled {
                        download.status = .failed(
                            .transportError(
                                urlError,
                                localizedDescription: error.localizedDescription
                            )
                        )
                    }
                } else {
                    download.status = .failed(
                        .unknown(
                            code: error.code,
                            localizedDescription: error.localizedDescription
                        )
                    )
                }
                return
            }

            guard let response = task.response as? HTTPURLResponse else {
                return
            }

            if !Set(200 ..< 300).contains(response.statusCode) {
                download.status = .failed(.serverError(statusCode: response.statusCode))
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            guard let download = self.taskIdentifiers[downloadTask.taskIdentifier] else {
                return
            }

            download.progress.fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }
    }
}
