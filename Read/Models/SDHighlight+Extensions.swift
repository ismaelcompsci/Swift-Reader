//
//  SDHighlight+Extensions.swift
//  Read
//
//  Created by Mirna Olvera on 5/14/24.
//

import Foundation
import SwiftReader

extension SDHighlight {
    func toPDFHighlight() -> PDFHighlight? {
        guard let highlightId, let uuid = UUID(uuidString: highlightId),
              let posData = ranges?.data(using: .utf8),
              let pos = try? JSONDecoder().decode([PDFHighlight.PageLocation].self, from: posData)
        else {
            return nil
        }

        return PDFHighlight(uuid: uuid, pos: pos, content: highlightText)
    }
}
