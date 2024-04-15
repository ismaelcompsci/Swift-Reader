//
//  SourceBookImage.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import NukeUI
import SwiftUI

struct SourceBookImage: View {
    let imageUrl: String?

    var title: String?
    var author: String?

    init(
        imageUrl: String?,
        title: String? = nil,
        author: String? = nil
    ) {
        self.imageUrl = imageUrl
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
        Group {
            if let image = imageUrl, let imageUrl = URL(string: image) {
                LazyImage(url: imageUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .spine()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }
}

#Preview {
    SourceBookImage(imageUrl: "")
}
