//
//  Download.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import Foundation

@Observable
public class Download: Identifiable, Hashable {
    public let id: Download.ID
    var request: URLRequest
    private var state: DownloadState

    public var url: URL {
        request.url!
    }

    public var status: DownloadState.Status {
        get {
            state.status
        }
        set {
            state.status = newValue
            NotificationCenter.default.post(
                .init(name: .downloadStatusChanged, object: self, userInfo: nil)
            )
        }
    }

    public var progress: DownloadProgress {
        state.progress
    }

    public init(
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

    public convenience init(
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

extension NSNotification.Name {
    static let downloadStatusChanged = Notification.Name(
        "SR.download-manager.download-status-changed"
    )
}
