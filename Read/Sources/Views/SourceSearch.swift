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

    var body: some View {
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

    func search() async {
        let query = SearchRequest(title: searchText, parameters: [:])

        self.query = query

        await withTaskGroup(of: (String, PagedResults?).self) { group in
            for (key, ext) in self.sourceManager.extensions.filter({ $0.value.sourceInfo.interfaces.search == true }) {
                let searchResult = SearchResults(source: ext.sourceInfo, results: nil)
                searchResult.state = .loading

                DispatchQueue.main.async {
                    self.searchResults[key] = searchResult
                }

                group.addTask {
                    let results = try? await ext.getSearchResults(query: query, metadata: [:])

                    return (key, results)
                }
            }

            for await (key, results) in group {
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
