//
//  BookDetailView.swift
//  Read
//
//  Created by Mirna Olvera on 1/30/24.
//

import RealmSwift
import SwiftUI

struct BookDetailView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme
    
    var book: Book
    
    var isPDF: Bool {
        book.bookPath?.hasSuffix(".pdf") ?? false
    }

    @State private var readMore = false
    @State private var openReader = false
    @State private var sImage: Image?
    @State private var infoSize: CGSize = .zero
    @Namespace private var animation
    
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
    
    func setHeaderImage() {
        guard let lastPathComponent = book.coverPath else {
            print("NO COVER PATH")
            return
        }
        
        let fullBookPath = URL.documentsDirectory.appending(path: lastPathComponent)
        
        guard let imageData = try? Data(contentsOf: fullBookPath), let originalImage = UIImage(data: imageData) else {
            print("BAD DATA")
            return
        }
        
        if imageData.count < 1000000 {
            sImage = Image(uiImage: originalImage)
        } else {
            if let compressedImageData = originalImage.jpeg(.medium), let compressedImage = UIImage(data: compressedImageData) {
                sImage = Image(uiImage: compressedImage)
            }
        }
    }
    
    @ViewBuilder
    var headerImage: some View {
        if let stateImage = sImage {
            stateImage
                .resizable()
                .scaledToFill()
            
        } else {
            BookCover(coverPath: nil, title: book.title, author: book.authors.first?.name)
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                let imageHeight = getImageHeight(proxy: proxy)
                
                GeometryReader { geometry in
                    ZStack {
                        let calcImageHeight = self.getHeightForHeaderImage(geometry)
                        let calcImageWidth = horizontalSizeClass == .regular ? (
                            geometry.size.width / 2
                        ) / 1.4 : geometry.size.width
                        
                        headerImage
                            .matchedGeometryEffect(id: "bookCover", in: animation)
                            .frame(
                                width: calcImageWidth,
                                height: calcImageHeight
                            )
                            .offset(
                                x: 0 - proxy.safeAreaInsets.trailing,
                                y: self.getOffsetForHeaderImage(geometry)
                            )
                            
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.clear,
                                    Color.black.opacity(0.30),
                                    Color.black.opacity(0.60),
                                    Color.black,
                                    Color.black
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .frame(height: imageHeight)
                
                VStack(alignment: .leading, spacing: 0) {
                    detailsView(proxy: proxy)
                        .frame(maxHeight: .infinity)
                        .readSize(onChange: { size in
                            infoSize = size
                        })
                    
                    paddingView(proxy: proxy, imageHeight: imageHeight)
                }
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(.container, edges: .top)
        .toolbarBackground(Color.black.opacity(0.5))
        .onAppear {
            setHeaderImage()
        }
        .fullScreenCover(isPresented: $openReader, content: {
            Reader(book: book)
        })
    }
    
    @ViewBuilder
    func paddingView(
        proxy: GeometryProxy,
        imageHeight: CGFloat
    ) -> some View {
        let viewHeight = proxy.size.height
        let combinedHeight = imageHeight + infoSize.height
        let padViewHeight = viewHeight - combinedHeight
        
        if combinedHeight < viewHeight {
            Rectangle()
                .fill(.black)
                .frame(width: proxy.size.width, height: padViewHeight)
        }
    }

    @ViewBuilder
    func detailsView(proxy: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            headerView
            
            VStack(alignment: .leading) {
                HStack {
                    let text: String = book.readingPosition != nil ? "Continue Reading \(Int((book.readingPosition?.progress ?? 0.0) * 100))%" : "Read"
                    
                    SRButton(systemName: "book.fill", text: text) {
                        withAnimation(.spring()) {
                            openReader = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: proxy.safeAreaInsets.trailing == 0 ? proxy.size.width : proxy.size.width)
                
                summaryView
                    .frame(width: proxy.size.width + 12)
                
                TagScrollView(tags: book.tags.map { $0.name })
                
                Spacer()
            }
            .background(.black)
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.title)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(theme.tintColor)
                    
                    Text(book.authors.first?.name ?? "Unknown Author")
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    var summaryView: some View {
        // MARK: Book Summary

        let text = book.summary?.stripHTML() ?? ""
        if text.isEmpty == false {
            MoreText(text: text)
                .tint(theme.tintColor)
        }
    }
}

#Preview {
    BookDetailView(book: .shortExample)
        .preferredColorScheme(.dark)
        .environment(AppTheme.shared)
}
