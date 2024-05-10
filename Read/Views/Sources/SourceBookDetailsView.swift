//
//  SourceBookDetailsView.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import OSLog
import SwiftUI

struct SourceBookDetailsView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SourceManager.self) private var sourceManager
    @State var extensionJS: SRExtension?

    @State private var bookDetails: SourceBook?
    @State private var loadingState: Bool = false

    var sourceId: String
    var item: PartialSourceBook

    var body: some View {
        ScrollView {
            BookDetails(
                image: bookDetails?.bookInfo.image ?? item.image ?? "",
                title: bookDetails?.bookInfo.title ?? item.title,
                description: bookDetails?.bookInfo.desc ?? "",
                author: bookDetails?.bookInfo.author ?? item.author ?? "Unknown Author",
                tags: bookDetails?.bookInfo.tags ?? []
            ) {
                Group {
                    if loadingState == false, let bookDetails {
                        SourceDownloadButton(
                            book: bookDetails
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
            }
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

            guard let extensionJS = extensionJS else {
                loadingState = false
                return
            }

            do {
                let details = try await extensionJS.getBookDetails(for: item.id)

                bookDetails = details
            } catch {
                // TODO: ERROR
                Logger.general.error("Something went wrong getting book details: \(error.localizedDescription)")
            }

            loadingState = false
        }
    }
}

#Preview {
    SourceBookDetailsView(sourceId: "", item: PartialSourceBook(id: "", title: ""))
}
