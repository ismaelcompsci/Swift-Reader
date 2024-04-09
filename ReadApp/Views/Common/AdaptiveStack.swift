//
//  AdaptiveStack.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import SwiftUI

struct AdaptiveStack<Content: View>: View {
    let content: () -> Content
    let isVertical: Bool
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment

    init(horizontalAlignment: HorizontalAlignment = .center,
         verticalAlignment: VerticalAlignment = .center,
         isVertical: Bool,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.isVertical = isVertical
        self.content = content
    }

    var body: some View {
        Group {
            if isVertical {
                VStack(alignment: horizontalAlignment, content: content)
            } else {
                HStack(alignment: verticalAlignment, content: content)
            }
        }
    }
}

#Preview {
    AdaptiveStack(verticalAlignment: .center, isVertical: false) {
        Text("HELLO")
    }
}
