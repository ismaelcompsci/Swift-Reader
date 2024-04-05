//
//  SourceSearch.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

@Observable
class SearchResults {
    var source: SourceInfo
    var results: PagedResults?
    var state: State = .loading

    enum State {
        case loading
        case error
        case done
    }

    init(source: SourceInfo, results: PagedResults? = nil) {
        self.source = source
        self.results = results
    }
}

struct SourceSearch: View {
    @EnvironmentObject var appColor: AppColor
    @Environment(SourceManager.self) private var sourceManager

    @State var searchResults: [String: SearchResults] = [:]
    @State var query: SearchRequest?

    @State var searchText = ""
    @State var isSearching = false

    @State private var currentSearchTask: Task<Void, Never>? = nil

    var body: some View {
        if sourceManager.sources.isEmpty {
            ContentUnavailableView(
                "No sources",
                systemImage: "gear.badge",
                description: Text("Add a source in settings")
            )
            .navigationTitle("Search Everything")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ScrollView {
                ForEach(self.searchResults.keys.sorted(), id: \.self) { key in

                    if let results = searchResults[key] {
                        switch results.state {
                        case .loading:
                            HStack {
                                Text(results.source.name)
                                    .font(.title2)
                                    .lineLimit(1)
                                    .fontWeight(.semibold)
                                    .padding(.leading, 10)

                                Spacer()

                                ProgressView()
                                    .padding(.trailing, 8)
                            }

                        case .done:
                            let resultsItems = results.results?.results ?? []

                            SourceSectionView(
                                title: results.source.name,
                                containsMoreItems: results.results?.metadata != nil,
                                items: resultsItems,
                                sourceId: results.source.id,
                                isLoading: false,
                                searchRequest: query
                            )

                        case .error:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle("Search Everything")
            .searchable(text: self.$searchText, isPresented: self.$isSearching)
            .tint(appColor.accent)
            .onSubmit(of: .search) {
                Task {
                    await self.search()
                }
            }
        }
    }

    func search() async {
        guard !searchText.isEmpty else { return }

        let query = SearchRequest(title: searchText, parameters: [:])
        self.query = query

        for (i, (key, ext)) in sourceManager.extensions.enumerated() {
            Task {
                guard ext.sourceInfo.interfaces.search == true else { return }

                let searchResult = SearchResults(source: ext.sourceInfo, results: nil)
                searchResult.state = .loading

                DispatchQueue.main.async {
                    self.searchResults[key] = searchResult
                }

                let results = try? await ext.getSearchResults(query: query, metadata: [:])

                DispatchQueue.main.async {
                    if let results {
                        self.searchResults[key]?.results = results
                        withAnimation {
                            self.searchResults[key]?.state = .done
                        }

                    } else {
                        self.searchResults[key]?.state = .error
                    }
                }
            }
        }
    }
}

#Preview {
    SourceSearch()
}
