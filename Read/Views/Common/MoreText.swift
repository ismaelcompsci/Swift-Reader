//
//  MoreText.swift
//  Read
//
//  Created by Mirna Olvera on 4/9/24.
//

import SwiftUI

struct MoreText: View {
    var text: String

    @State private var readMore: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(text)
                .lineLimit(readMore ? 100 : 4)
                .font(.subheadline)
                .onTapGesture {
                    readMore.toggle()
                }

            if !text.isEmpty {
                Button(readMore ? "less" : "more") {
                    readMore.toggle()
                }
            }
        }
    }
}

#Preview {
    MoreText(text: "this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. this is lorem ipsum. ")
}
