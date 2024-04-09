//
//  TagScrollView.swift
//  Read
//
//  Created by Mirna Olvera on 4/9/24.
//

import SwiftUI

struct TagScrollView: View {
    var tags: [String]

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(tags.indices, id: \.self) { index in
                    Text(tags[index])
                        .font(.system(size: 14))
                        .lineLimit(1)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(.fill)
                        )
                        .padding(2)
                        .padding(.leading, index == 0 ? 6 : 0)
                }
            }
        }
    }
}

#Preview {
    TagScrollView(tags: ["Fantasy", "Grim", "Dark", "Medival"])
        .preferredColorScheme(.dark)
}
