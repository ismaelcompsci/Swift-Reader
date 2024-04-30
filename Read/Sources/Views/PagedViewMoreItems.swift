//
//  PagedViewMoreItems.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import OSLog
import SwiftUI

struct PagedViewMoreItems: View {
    @Environment(SourceManager.self) private var sourceManager
    @State var extensionJS: SRExtension?

    var sourceId: String
    var viewMoreId: String

    @State var isFinished = false
    @State var isLoading = false

    @State var books = [PartialSourceBook]()
    @State var metadata: Any?

    let size: CGFloat = 120

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: self.size))],
                spacing: 8
            ) {
                ForEach(self.books) { book in

                    SourceBookCard(book: book, sourceId: self.sourceId)
                }

                if !self.isFinished {
                    HStack(alignment: .center, spacing: 16) {
                        ProgressView()
                        Text("Loading...")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(8)
                    .background(.ultraThickMaterial)
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.horizontal)
                    .onAppear {
                        self.getMoreHomeViewItems()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            self.checkExtension()
        }
    }

    func checkExtension() {
        if self.extensionJS == nil {
            self.extensionJS = self.sourceManager.extensions[self.sourceId]
        }
    }

    func getMoreHomeViewItems() {
        self.checkExtension()
        guard let extensionJS = extensionJS else { return }

        if !self.isLoading {
            self.isLoading = true

            Task {
                do {
                    let moreItems = try await extensionJS.getViewMoreItems(homepageSectionId: self.viewMoreId, metadata: self.metadata)

                    self.books.append(contentsOf: moreItems.results)
                    if let metadata = moreItems.metadata {
                        self.metadata = metadata
                    } else {
                        self.isFinished = true
                    }

                } catch {
                    // TODO: EROROR
                    Logger.general.error("Paged View More Items Error: \(error.localizedDescription)")
                    self.isFinished = true
                }

                self.isLoading = false
            }
        }
    }
}

#Preview {
    PagedViewMoreItems(sourceId: "", viewMoreId: "")
}
