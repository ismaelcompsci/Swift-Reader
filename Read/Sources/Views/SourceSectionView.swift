//
//  SourceSectionView.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

struct SourceSectionView: View {
    @Environment(AppTheme.self) var theme

    var title: String
    var containsMoreItems: Bool
    var items: [PartialSourceBook]

    var sourceId: String
    var id: String?
    var isLoading: Bool

    var searchRequest: SearchRequest?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(self.title)
                    .font(.title2)
                    .lineLimit(1)
                    .fontWeight(.semibold)
                    .padding(.leading, 10)

                Spacer()

                if isLoading {
                    ProgressView()
                } else if self.containsMoreItems == true {
                    NavigationLink {
                        if let id = id {
                            PagedViewMoreItems(sourceId: self.sourceId, viewMoreId: id)
                                .navigationTitle(title)
                        } else if let searchRequest = searchRequest {
                            SourcesSearchPagedResultsView(searchRequest: searchRequest, sourceId: sourceId)
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .padding(.trailing, 8)
                    .tint(theme.tintColor)
                }
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(self.items, id: \.self) { book in
                        SourceBookCard(book: book, sourceId: self.sourceId)
                    }
                }
                .transition(.slide)
                .animation(.snappy, value: self.items)
            }
            .contentMargins(10, for: .scrollContent)
            .listRowInsets(EdgeInsets())
        }
    }
}

#Preview {
    SourceSectionView(
        title: "",
        containsMoreItems: false,
        items: [],
        sourceId: "123",
        id: "",
        isLoading: false
    )
}
