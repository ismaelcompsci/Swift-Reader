//
//  BookDetailView.swift
//  Read
//
//  Created by Mirna Olvera on 1/30/24.
//

import RealmSwift
import SwiftUI

final class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    
    @Published var orientation: Orientation
    
    private var _observer: NSObjectProtocol?
    
    init() {
        // fairly arbitrary starting value for 'flat' orientations
        if UIDevice.current.orientation.isLandscape {
            self.orientation = .landscape
        } else {
            self.orientation = .portrait
        }
        
        // unowned self because we unregister before self becomes invalid
        self._observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
            guard let device = note.object as? UIDevice else {
                return
            }
            if device.orientation.isPortrait {
                self.orientation = .portrait
            } else if device.orientation.isLandscape {
                self.orientation = .landscape
            }
        }
    }
    
    deinit {
        if let observer = _observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

struct BookDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appColor: AppColor
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    var book: Book
    
    var isPDF: Bool {
        book.bookPath?.hasSuffix(".pdf") ?? false
    }

    @State private var readMore = false
    @State private var openReader = false
    
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
    
    var bookImage: Image {
        let image = getBookCover(path: book.coverPath)
        
        if let image {
            return Image(uiImage: image)
               
        } else {
            return Image(systemName: "book.pages.fill")
        }
    }
    
    func getImageHeight(proxy: GeometryProxy) -> CGFloat {
        let screenHeight = proxy.size.height
        
        if screenHeight <= 1000 {
            return screenHeight / 2
        } else {
            return UIScreen.main.bounds.height * 0.78
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                // 1
                GeometryReader { geometry in
                    ZStack {
                        bookImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: orientationInfo.orientation == .landscape ? (geometry.size.width / 2) / 1.4 : geometry.size.width, height: self.getHeightForHeaderImage(geometry))
                            .offset(x: 0, y: self.getOffsetForHeaderImage(geometry))
                        
                        LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.30), Color.black.opacity(0.70), Color.black, Color.black]), startPoint: .top, endPoint: .bottom)
                    }
                }
                .frame(height: getImageHeight(proxy: proxy))
                
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(book.title)
                                .font(.title)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(appColor.accent)
                                
                                Text(book.authors.first?.name ?? "Unknown Author")
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    // 2
                    //                Text("02 January 2019 • 5 min read")
                    //                    .font(.subheadline)
                    //                    .foregroundColor(.gray)
                    //
                    
                    HStack {
                        Button {
                            openReader = true
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                
                                if let position = book.readingPosition {
                                    Text("Continue Reading \(Int((position.progress ?? 0.0) * 100))%")
                                } else {
                                    Text("Read")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(appColor.accent)
                            .clipShape(.capsule)
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    let isEmpty = book.summary?.stripHTML().isEmpty
                    if let isEmpty, isEmpty == false {
                        VStack(alignment: .leading) {
                            // MARK: Book Summary
                            
                            let text = book.summary?.stripHTML() ?? ""
                            
                            Text(text)
                                .padding(.horizontal, 12)
                                .lineLimit(readMore ? 9999 : 6)
                                .font(.subheadline)
                                .onTapGesture {
                                    readMore.toggle()
                                }
                            
                            if !text.isEmpty {
                                Button(readMore ? "less" : "more") {
                                    readMore.toggle()
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .frame(width: proxy.size.width)
                        .background(.black)
                    }
                    
                    // MARK: Book Tags
                    
                    if book.tags.count > 0 {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(book.tags.indices, id: \.self) { index in
                                    Text(book.tags[index].name)
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                                        )
                                        .padding(2)
                                        .padding(.leading, index == 0 ? 6 : 0)
                                }
                            }
                        }
                    }
                    
                    Color.black
                        .frame(width: UIScreen.main.bounds.width, height: 300)
                        .offset(x: 0, y: -7)
                }
                .background(
                    LinearGradient(colors: [Color.clear, Color.black], startPoint: .top, endPoint: .bottom)
                )
            }
        }
        .scrollIndicators(.hidden)
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $openReader, content: {
            let bookPathURL = URL.documentsDirectory.appending(path: book.bookPath ?? "")
            let url = bookPathURL
            let isPDF = bookPathURL.lastPathComponent.hasSuffix(".pdf")
            
            if isPDF {
                PDF(url: url, book: book)
            } else {
                EBookView(url: url, book: book)
            }

        })
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .toolbarBackground(Color.black.opacity(0.5))
        .tint(appColor.accent)
    }
}

#Preview {
    BookDetailView(book: .example1)
        .environmentObject(AppColor())
        .preferredColorScheme(.dark)
}
