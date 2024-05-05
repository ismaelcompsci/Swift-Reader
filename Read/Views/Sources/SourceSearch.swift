//
//  SourceSearch.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import OSLog
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
    @Environment(AppTheme.self) var theme
    @Environment(SourceManager.self) private var sourceManager

    @State var searchResults: [String: SearchResults] = [:]
    @State var query: SearchRequest?

    @State var searchText = ""
    @State var isSearching = false

    init(searchText: String = "") {
        self._searchText = State(initialValue: searchText)
    }

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
                ForEach(searchResults.keys.sorted(), id: \.self) { key in

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
            .searchable(text: $searchText, isPresented: $isSearching)
            .tint(theme.tintColor)
            .onSubmit(of: .search) {
                Task {
                    query = nil
                    await search()
                }
            }
            .task {
                if searchText.isEmpty == false && query == nil {
                    await search()
                }
            }
        }
    }

    func search() async {
        guard !searchText.isEmpty else { return }

        let query = SearchRequest(title: searchText, parameters: [:])
        self.query = query

        for (_, (key, ext)) in sourceManager.extensions.enumerated() {
            Task {
                guard ext.sourceInfo.interfaces.search == true else { return }

                let searchResult = SearchResults(source: ext.sourceInfo, results: nil)
                searchResult.state = .loading

                DispatchQueue.main.async {
                    self.searchResults[key] = searchResult
                }

                do {
                    let paged = try await ext.getSearchResults(query: query, metadata: [:])
                    self.searchResults[key]?.results = paged

                    withAnimation {
                        self.searchResults[key]?.state = .done
                    }
                } catch {
                    // TODO: ERROR TODO

                    Logger.general.error("Searching sources error: \(error.localizedDescription)")
                    self.searchResults[key]?.state = .error
                }
            }
        }
    }
}

#Preview {
    SourceSearch()
}
