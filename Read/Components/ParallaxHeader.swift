//
//  ParallaxHeader.swift
//  Read
//
//  Created by Mirna Olvera on 2/3/24.
//

import SwiftUI

struct ParallaxHeader<Content: View, Space: Hashable>: View {
    let content: () -> Content
    let coordinateSpace: Space
    let defaultHeight: CGFloat

    init(
        coordinateSpace: Space,
        defaultHeight: CGFloat,
        @ViewBuilder _ content: @escaping () -> Content
    ) {
        self.content = content
        self.coordinateSpace = coordinateSpace
        self.defaultHeight = defaultHeight
    }

    var body: some View {
        GeometryReader { proxy in
            let offset = offset(for: proxy)
            let heightModifier = heightModifier(for: proxy)

            content()
                .edgesIgnoringSafeArea(.horizontal)
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height + heightModifier
                )
                .offset(y: offset)

            LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.40), Color.black.opacity(0.80), Color.black]), startPoint: .top, endPoint: .bottom)
        }
        .frame(height: defaultHeight)
    }

    private func offset(for proxy: GeometryProxy) -> CGFloat {
        let frame = proxy.frame(in: .named(coordinateSpace))

        if frame.minY < 0 {
            return -frame.minY * 0.1
        }

        return -frame.minY
    }

    private func heightModifier(for proxy: GeometryProxy) -> CGFloat {
        let frame = proxy.frame(in: .named(coordinateSpace))

        if frame.minY > 150 {
            return frame.minY - 150 + 25
        }

        return 25
    }
}

#Preview {
    ParallaxHeader(coordinateSpace: "scroll", defaultHeight: 600) {
        Image(systemName: "user")
    }
}
