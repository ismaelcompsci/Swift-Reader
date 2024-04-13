//
//  TagScrollView.swift
//  Read
//
//  Created by Mirna Olvera on 4/9/24.
//

import SwiftUI

struct TagItem: View {
    var name: String
    var small: Bool = false

    init(name: String, small: Bool = false) {
        self.name = name
        self.small = small
    }

    var body: some View {
        Text(name)
            .font(.system(size: small ? 10 : 14))
            .lineLimit(1)
            .padding(.vertical, small ? 3 : 4)
            .padding(.horizontal, small ? 6 : 12)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(.thinMaterial)
            )
            .padding(2)
    }
}

struct TagScrollView: View {
    var tags: [String]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(tags.indices, id: \.self) { index in
                    TagItem(name: tags[index])
                        .padding(.leading, index == 0 ? 6 : 0)
                }
            }
        }
    }
}

#Preview {
    VStack {
        TagScrollView(tags: ["Fantasy", "Grim", "Dark", "Medival"])
            .preferredColorScheme(.light)
    }
}
