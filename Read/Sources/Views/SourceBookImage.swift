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

    var title: String? = "Assassin's Quest"
    var author: String? = "Robbin Hobb"

    var placeholder: some View {
        Image(systemName: "books.vertical")
    }

    var body: some View {
        Group {
            if let image = imageUrl, let imageUrl = URL(string: image) {
                LazyImage(url: imageUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image(systemName: "xmark")
                    } else {
                        ProgressView()
                    }
                }

            } else {
                self.placeholder
            }
        }
    }
}

#Preview {
    SourceBookImage(imageUrl: "")
}
