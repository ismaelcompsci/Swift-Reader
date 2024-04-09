//
//  ParallaxHeader.swift
//  Read
//
//  Created by Mirna Olvera on 4/9/24.
//

import NukeUI
import SwiftUI

struct ParallaxHeader: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    @MainActor
    var headerImage: some View {
        LazyImage(url: URL(
            string: "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1647789287i/60177373.jpg"
        )) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if state.error != nil {
                Color.red // Indicates an error
            } else {
                Color.blue // Acts as a placeholder
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let calcImageHeight = self.getHeightForHeaderImage(geometry)
                let calcImageWidth = horizontalSizeClass == .regular ? (
                    geometry.size.width / 2
                ) / 1.4 : geometry.size.width
                
                let _ = print("IMAGE GHEIHTH", calcImageHeight)

                headerImage
                    .frame(
                        width: calcImageWidth,
                        height: calcImageHeight
                    )
                    .offset(
                        x: 0 - geometry.safeAreaInsets.trailing,
                        y: self.getOffsetForHeaderImage(geometry)
                    )
                
//                LinearGradient(colors: [Color.black, Color.clear], startPoint: .bottom, endPoint: .top)
//
//                LinearGradient(
//                    gradient: Gradient(
//                        colors: [
//                            Color.clear,
//                            Color.black.opacity(0.30),
//                            Color.black.opacity(0.70),
//                            Color.black,
//                        ]
//                    ),
//                    startPoint: .top,
//                    endPoint: .center
//                )
            }
        }
        .frame(
            height: 400
        )
        .border(.green)
    }
    
    private func getHeightForHeaderImage(_ geometry: GeometryProxy) -> CGFloat {
        let offset = getScrollOffset(geometry)
        let imageHeight = geometry.size.height

        if offset > 150 {
            return imageHeight + offset
        }

        return imageHeight + 150
    }
    
    private func getScrollOffset(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.frame(in: .global).minY
    }
        
    private func getOffsetForHeaderImage(_ geometry: GeometryProxy) -> CGFloat {
        let offset = getScrollOffset(geometry)
            
        if offset > 0 {
            return -offset
        }
            
        return 0
    }
    
    var imageFrame: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        
        if screenHeight <= 1000 {
            return screenHeight / 2
        } else {
            return UIScreen.main.bounds.height * 0.78
        }
    }
    
    func getImageHeight(proxy: GeometryProxy) -> CGFloat {
        let screenHeight = proxy.size.height
        
        if screenHeight <= 1000 {
            return screenHeight / 2
        } else {
            return screenHeight * 0.78
        }
    }
}

#Preview {
    ScrollView {
        ParallaxHeader()
        ZStack {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.5),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            
            VStack(alignment: .leading) {
                Text("HELLO WORLD!")
                
                Text("author now")
            }
            .frame(maxWidth: .infinity)
            .background(.black)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
    }
        
    .background(.blue)
    .preferredColorScheme(.dark)
    .ignoresSafeArea(.container, edges: .top)
}
