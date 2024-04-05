//
//  SourceBookDetailsView.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

struct SourceBookDetailsView: View {
    @Environment(SourceManager.self) private var sourceManager
    @State var extensionJS: SourceExtension?

    @State private var showMore = false
    @State private var bookDetails: SourceBook?
    @State private var loadingState: Bool = false

    var sourceId: String
    var item: PartialSourceBook

    var downloadable: Bool {
        bookDetails?.bookInfo.downloadLinks.count != 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 10) {
                    SourceBookImage(imageUrl: bookDetails?.bookInfo.image ?? item.image)
                        .frame(width: 114, height: 114 * 1.5)
                        .clipShape(.rect(cornerRadius: 6))

                    VStack(alignment: .leading) {
                        Text(bookDetails?.bookInfo.title ?? item.title)
                            .font(.system(size: 22, weight: .semibold))
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(bookDetails?.bookInfo.author ?? item.author ?? "Unknown Author")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let desc = bookDetails?.bookInfo.desc {
                    VStack(spacing: 0) {
                        Text(desc)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .lineLimit(self.showMore ? 40 : 3)
                            .allowsTightening(false)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    self.showMore.toggle()
                                }
                            }

                        Text(self.showMore ? "less" : "more")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    self.showMore.toggle()
                                }
                            }
                    }
                }

                if loadingState == false, let bookDetails {
                    SourceDownloadButton(
                        downloadUrls: bookDetails.bookInfo.downloadLinks,
                        downloadable: self.downloadable,
                        book: bookDetails,
                        itemId: bookDetails.id
                    )

                } else {
                    Button {} label: {
                        HStack(spacing: 8) {
                            Text(loadingState ? "loading..." : "not available")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 32)
                    .disabled(true)
                    .clipShape(.rect(cornerRadius: 10))
                    .buttonStyle(.borderedProminent)
                }
            }
            .scenePadding()
        }
        .transition(.opacity)
        .animation(.snappy, value: loadingState)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if loadingState == true {
                    ProgressView()
                }
            }
        }
        .task {
            self.loadingState = true
            self.extensionJS = sourceManager.extensions[sourceId]

            if self.extensionJS?.loaded == false {
                _ = self.extensionJS?.load()
            }
            if let details = try? await self.extensionJS?.getBookDetails(for: self.item.id) {
                self.bookDetails = details
            }

            self.loadingState = false
        }
    }
}

#Preview {
    SourceBookDetailsView(sourceId: "", item: PartialSourceBook(id: "", title: ""))
}
