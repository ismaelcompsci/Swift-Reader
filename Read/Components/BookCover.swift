//
//  BookCover.swift
//  Read
//
//  Created by Mirna Olvera on 2/23/24.
//

import SwiftUI

struct BookCover: View {
    var image: Image

    var isPlaceholderImage: Bool = false

    init(coverPath: String? = nil) {
        let image = getBookCover(path: coverPath)

        if let image {
            self.image = Image(uiImage: image)
            isPlaceholderImage = false
        } else {
            self.image = Image(systemName: "book")
            isPlaceholderImage = true
        }
    }

    var body: some View {
        if isPlaceholderImage {
            image
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 10)
        } else {
            ZStack {
                image
                    .resizable()
                    .blur(radius: 8, opaque: true)

                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

#Preview {
    BookCover(coverPath: nil)
}
