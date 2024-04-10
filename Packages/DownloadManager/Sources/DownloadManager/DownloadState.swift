//
//  File.swift
//
//
//  Created by Mirna Olvera on 4/9/24.
//

import Foundation

public struct DownloadState: Equatable {
    public var status: Status
    public let progress: DownloadProgress

    public init(
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

    public static func ==(lhs: DownloadState, rhs: DownloadState) -> Bool {
        lhs.progress == rhs.progress
            && lhs.status == rhs.status
    }
}
