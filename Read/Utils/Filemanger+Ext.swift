//
//  Filemanger+Ext.swift
//  Read
//
//  Created by Mirna Olvera on 4/18/24.
//

import Foundation

public extension FileManager {
    func allocatedSizeOfDirectory(at directoryURL: URL) -> UInt64 {
        let enumerator = self.enumerator(at: directoryURL,
                                         includingPropertiesForKeys: Array(allocatedSizeResourceKeys),
                                         options: [],
                                         errorHandler: nil)!

        var accumulatedSize: UInt64 = 0

        for item in enumerator {
            let contentItemURL = item as! URL
            accumulatedSize += contentItemURL.regularFileAllocatedSize()
        }

        return accumulatedSize
    }
}

private let allocatedSizeResourceKeys: Set<URLResourceKey> = [
    .isRegularFileKey,
    .fileAllocatedSizeKey,
    .totalFileAllocatedSizeKey,
]

private extension URL {
    func regularFileAllocatedSize() -> UInt64 {
        let resourceValues = try? self.resourceValues(forKeys: allocatedSizeResourceKeys)

        guard let resourceValues = resourceValues, resourceValues.isRegularFile ?? false else {
            return 0
        }

        return UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
    }
}
