//
//  PlaceholderCover.swift
//  Read
//
//  Created by Mirna Olvera on 4/9/24.
//

import SwiftUI

struct PlaceholderCover: View {
    var title: String
    var author: String

    var randomColor: Color = .random()

    var body: some View {
        return GeometryReader { proxy in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            randomColor,
                            randomColor.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    VStack {
                        Text(title)
                            .getContrastText(backgroundColor: randomColor)
                            .font(.system(size: 48, weight: .semibold))
                            .minimumScaleFactor(0.01)
                            .multilineTextAlignment(.center)
                            .aspectRatio(9 / 16, contentMode: .fit)

                        Spacer()

                        Text(author)
                            .getContrastText(backgroundColor: randomColor)
                            .font(.system(size: 48, weight: .light))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.01)
                            .aspectRatio(9 / 16, contentMode: .fit)
                            .lineLimit(1)
                    }
                    .padding(8)
                    .frame(
                        width: proxy.size.width * 0.9,
                        height: proxy.size.height * 0.95
                    )
                }
                .overlay {
                    Rectangle()
                        .stroke(lineWidth: 0.5)
                        .frame(
                            width: proxy.size.width * 0.9,
                            height: proxy.size.height * 0.95
                        )
                }
        }
    }
}

struct SpineModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    gradient: Gradient(
                        stops: [
                            .init(
                                color: .black.opacity(0.3),
                                location: 0.008
                            ),
                            .init(color: Color.white.opacity(0.5), location: 0.01),
                            .init(color: Color.white.opacity(0.14), location: 0.01),
                            .init(color: Color.white.opacity(0.1), location: 0.025),
                            .init(color: Color.black.opacity(0.15), location: 0.03),
                            .init(color: Color.white.opacity(0.24), location: 0.05),
                            .init(color: Color.white.opacity(0.2), location: 0.055),
                            .init(color: Color.clear, location: 0.07)
                        ]
                    ),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
    }
}

extension View {
    func spine() -> some View {
        modifier(SpineModifier())
    }
}

#Preview {
    PlaceholderCover(
        title: "Unknown Title",
        author: "Unknown Author"
    )
}
