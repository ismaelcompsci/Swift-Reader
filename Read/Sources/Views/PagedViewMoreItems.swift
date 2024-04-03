//
//  PagedViewMoreItems.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

struct PagedViewMoreItems: View {
    @Environment(SourceManager.self) private var sourceManager
    @State var extensionJS: SourceExtension?

    var sourceId: String
    var viewMoreId: String

    @State var loading = false
    @State var cancel = false
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

                if self.cancel == false {
                    VStack(spacing: 12) {
                        ProgressView()
                        Spacer()
                        Text("Loading items")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(8)
                    .background(.ultraThickMaterial)
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.horizontal)
                    .onAppear {
                        Task {
                            if self.loading == true || self.cancel == true {
                                return
                            }

                            await self.getMoreHomeViewItems()
                        }
                    }
                }
            }
        }
        .navigationTitle("")
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

    func getMoreHomeViewItems() async {
        self.checkExtension()
        self.loading = true
        let results = try? await self.extensionJS?.getViewMoreItems(
            homepageSectionId: self.viewMoreId,
            metadata: self.metadata
        )

        if let results {
            self.books.append(contentsOf: results.results)

            if let metadata = results.metadata {
                self.metadata = metadata
            } else {
                self.cancel = true
            }
        } else {
            self.cancel = true
        }

        self.loading = false
    }
}

#Preview {
    PagedViewMoreItems(sourceId: "", viewMoreId: "")
}