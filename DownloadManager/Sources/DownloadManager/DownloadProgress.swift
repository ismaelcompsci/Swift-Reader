//
//  File.swift
//
//
//  Created by Mirna Olvera on 4/9/24.
//

import Foundation

@Observable
public class DownloadProgress: Identifiable, Hashable {
    public var id = UUID()
    public var fraction: Double = 0

    public init() {}

    public static func == (lhs: DownloadProgress, rhs: DownloadProgress) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
