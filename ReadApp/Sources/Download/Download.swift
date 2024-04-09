//
//  Download.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import Foundation

@Observable
class DownloadProgress: Identifiable, Hashable {
    var id = UUID()
    var fraction: Double = 0

    public static func == (lhs: DownloadProgress, rhs: DownloadProgress) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DownloadState {
    var status: Status
    let progress: DownloadProgress

    init(
        status: Status = .idle,
        progress: DownloadProgress = .init()
    ) {
        self.status = status
        self.progress = progress
    }

    public enum Status: Hashable {
        case idle
        case downloading
        case paused
        case finished
        case failed(Error)
    }

    public enum Error: Swift.Error, Hashable {
        case serverError(statusCode: Int)
        case transportError(URLError, localizedDescription: String)
        case unknown(code: Int, localizedDescription: String)
        case aggregate(errors: Set<Error>)
    }
}

@Observable
public class Download: Identifiable, Hashable {
    public var id: Download.ID
    var request: URLRequest
    var state: DownloadState

    public var url: URL {
        request.url!
    }

    var status: DownloadState.Status {
        get {
            state.status
        }
        set {
            state.status = newValue
        }
    }

    var progress: DownloadProgress {
        state.progress
    }

    init(
        id: Download.ID,
        request: URLRequest,
        status: DownloadState.Status = .idle,
        progress: DownloadProgress
    ) {
        self.id = id
        self.request = request
        self.state = .init(
            status: status,
            progress: progress
        )
    }

    convenience init(
        id: Download.ID,
        url: URL,
        status: DownloadState.Status = .idle,
        progress: DownloadProgress
    ) {
        self.init(
            id: id,
            request: URLRequest(url: url),
            status: status,
            progress: progress
        )
    }

    public static func == (lhs: Download, rhs: Download) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // swiftlint:disable:next type_name
    public typealias ID = String
}
