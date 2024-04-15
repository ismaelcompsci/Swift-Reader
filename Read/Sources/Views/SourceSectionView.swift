//
//  SourceSectionView.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

struct SourceSectionView: View {
    @Environment(Navigator.self) var navigator
    @Environment(AppTheme.self) var theme

    var title: String
    var containsMoreItems: Bool
    var items: [PartialSourceBook]

    var sourceId: String
    var id: String?
    var isLoading: Bool

    var searchRequest: SearchRequest?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.title2)
                    .lineLimit(1)
                    .fontWeight(.semibold)
                    .padding(.leading, 10)

                Spacer()

                Group {
                    if isLoading {
                        ProgressView()
                    } else if containsMoreItems == true {
                        Button {
                            if let id = id {
                                navigator.navigate(to: .sourcePagedViewMoreItems(sourceId: sourceId, viewMoreId: id))
                            } else if let searchRequest = searchRequest {
                                navigator.navigate(to: .sourceSearchPagedResults(searchRequest: searchRequest, sourceId: sourceId))
                            }
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                }
                .padding(.trailing, 8)
                .tint(theme.tintColor)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(items, id: \.self) { book in
                        SourceBookCard(book: book, sourceId: sourceId)
                    }
                    .transition(.opacity)
                }
                .transition(.move(edge: .bottom))
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
