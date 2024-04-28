//
//  SourcesSearchPagedResultsView.swift
//  Read
//
//  Created by Mirna Olvera on 4/3/24.
//

import SwiftUI

struct SourcesSearchPagedResultsView: View {
    @Environment(AppTheme.self) var theme
    @Environment(SourceManager.self) var sourceManager
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
        .navigationTitle(self.searchRequest.title ?? "Search")
        .navigationBarTitleDisplayMode(.inline)
        .tint(self.theme.tintColor)
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

        guard let extensionJS = self.extensionJS else {
            self.loading = false
            return
        }

        let query = SearchRequest(title: searchRequest.title, parameters: [:])

        do {
            let searchResults = try await extensionJS.getSearchResults(query: query, metadata: self.metadata as Any)
            self.books.append(contentsOf: searchResults.results)

            if let metadata = searchResults.metadata {
                self.metadata = metadata
            } else {
                self.cancel = true
            }

        } catch {
            // TODO: ERROR
            Log("Failed to get search results: \(error.localizedDescription)")
            self.cancel = true
        }
        self.loading = false
    }
}

#Preview {
    SourcesSearchPagedResultsView(searchRequest: .init(title: "", parameters: [:]), sourceId: "")
}
