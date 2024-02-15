//
//  BookDetailView.swift
//  Read
//
//  Created by Mirna Olvera on 1/30/24.
//

import RealmSwift
import SwiftUI

struct BookDetailView: View {
    @Environment(\.dismiss) var dismiss
    var book: Book
    
    var isPDF: Bool {
        book.bookPath?.hasSuffix(".pdf") ?? false
    }

    @State private var readMore = false

    private enum CoordinateSpaces {
        case scrollView
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ParallaxHeader(
                    coordinateSpace: CoordinateSpaces.scrollView,
                    defaultHeight: 620
                ) {
                    Image(uiImage: getBookCover(path: book.coverPath) ?? UIImage())
                        .resizable()
                        .scaledToFill()
                }
                
                VStack {
                    // MARK: Title & Author
                    
                    VStack(alignment: .leading) {
                        Text(book.title)
                            .font(.title)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.accent)
                            
                            Text(book.author.first?.name ?? "Unknown Author")
                        }
                        .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    
                    // MARK: Read Book
                    
                    VStack(alignment: .leading) {
                        HStack {
                            NavigationLink {
                                if !isPDF {
                                    EBookReader(book: book)
                                } else {
//                                    Text("PDF not supported!")
                                    PDFReader(book: book)
                                }
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
                                .background(Color.accent)
                                .clipShape(.capsule)
                            }
                        }
                        
                        // MARK: Book Summary
                        
                        VStack(alignment: .leading) {
                            let text = book.summary?.stripHTML() ?? ""
                            
                            Text(text)
                                .lineLimit(readMore ? 9999 : 6)
                                .onTapGesture {
                                    readMore.toggle()
                                }
                            
                            if !text.isEmpty {
                                Button(readMore ? "less" : "more") {
                                    readMore.toggle()
                                }
                            }
                        }
                        
                        // MARK: Book Tags
                        
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(book.tags, id: \.self) { tag in
                                    Text(tag.name)
                                        .font(.system(size: 14))
                                        .lineLimit(1)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                                        )
                                        .padding(2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(.black)
                    
                    Spacer()
                }
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.60), Color.black, Color.black]), startPoint: .top, endPoint: .bottom)
                )
                .frame(minHeight: 350)
                .offset(y: -250)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollIndicators(.hidden)
            .coordinateSpace(name: CoordinateSpaces.scrollView)
            .edgesIgnoringSafeArea(.top)
            .navigationBarBackButtonHidden(true)
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
            .tint(Color.accent)
        }
    }
}

#Preview {
    BookDetailView(book: Book(value: ["title": "A book that is here", "summary": "Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser Hey loser "]))
        .preferredColorScheme(.dark)
}
