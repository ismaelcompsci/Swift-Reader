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
    var title: String?
    var author: String?

    init(coverPath: String? = nil, title: String? = nil, author: String? = nil) {
        if let path = coverPath {
            isPlaceholderImage = false
            imageURL = getCoverFullPath(for: path)
        } else {
            isPlaceholderImage = true
            imageURL = nil
        }

        self.title = title
        self.author = author
    }

    var placeholder: some View {
        PlaceholderCover(
            title: title ?? "Unknown Title",
            author: author ?? "Unknown Author"
        )
        .aspectRatio(0.7, contentMode: .fill)
        .spine()
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
                        .spine()

                } else {
                    placeholder
                }
            }
        }
    }
}

#Preview {
    BookCover(coverPath: nil)
        .preferredColorScheme(.light)
        .frame(width: 100, height: 160)
}
