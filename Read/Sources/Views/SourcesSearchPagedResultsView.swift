//
//  SourcesSearchPagedResultsView.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import SwiftUI

struct SourcesSearchPagedResultsView: View {
    @EnvironmentObject var appColor: AppColor
    @Environment(SourceManager.self) private var sourceManager
    @State var extensionJS: SourceExtension?

    @State var books = [PartialSourceBook]()

    var searchRequest: SearchRequest
    var sourceId: String

    @State var metadata: Any?
    @State var loading = false
    @State var cancel = false

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
                            .minimumScaleFactor(0.01)
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

                            await self.getSearchResults()
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(self.appColor.accent)
        .task {
            self.checkExtension()
        }
    }

    func checkExtension() {
        if self.extensionJS == nil {
            self.extensionJS = self.sourceManager.extensions[self.sourceId]
        }
    }

    func getSearchResults() async {
        self.loading = true
        self.checkExtension()

        let query = SearchRequest(title: searchRequest.title, parameters: [:])
        let results = try? await self.extensionJS?.getSearchResults(
            query: query,
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
    SourcesSearchPagedResultsView(searchRequest: .init(title: "", parameters: [:]), sourceId: "")
}
