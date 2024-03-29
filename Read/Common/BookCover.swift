//
//  BookCover.swift
//  Read
//
//  Created by Mirna Olvera on 2/23/24.
//

import NukeUI
import SwiftUI

func getCoverFullPath(for path: String) -> URL {
    let documentsPath = URL.documentsDirectory
    return documentsPath.appending(path: path)
}

struct BookCover: View {
    var imageURL: URL?
    var isPlaceholderImage: Bool = false

    init(coverPath: String? = nil) {
        if let path = coverPath {
            isPlaceholderImage = false
            imageURL = getCoverFullPath(for: path)
        } else {
            isPlaceholderImage = true
            imageURL = nil
        }
    }

    var placeholder: some View {
        Image(systemName: "book")
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 10)
    }

    var body: some View {
        if isPlaceholderImage {
            placeholder
        } else {
            LazyImage(url: imageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "ellipsis")
                        .symbolEffect(.variableColor)
                }
            }
        }
    }
}

#Preview {
    BookCover(coverPath: nil)
}
