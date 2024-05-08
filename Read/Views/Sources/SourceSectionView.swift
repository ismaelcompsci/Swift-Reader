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

    var section: SRHomeSection
    var sourceId: String
    var searchRequest: SearchRequest?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(section.title)
                    .font(.title2)
                    .lineLimit(1)
                    .fontWeight(.semibold)
                    .padding(.leading, 10)

                Spacer()

                Group {
                    if section.items.isEmpty {
                        ProgressView()
                    } else if section.containsMoreItems == true {
                        Button {
                            if let searchRequest = searchRequest {
                                navigator.navigate(to: .sourceSearchPagedResults(searchRequest: searchRequest, sourceId: sourceId))
                            } else {
                                navigator.navigate(to: .sourcePagedViewMoreItems(sourceId: sourceId, viewMoreId: section.id))
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
                    ForEach(section.items, id: \.self) { book in
                        SourceBookCard(book: book, sourceId: sourceId)
                    }
                }
            }
            .contentMargins(10, for: .scrollContent)
            .listRowInsets(EdgeInsets())
        }
    }
}

#Preview {
    SourceSectionView(
        section: .init(id: "", title: "", items: [], containsMoreItems: false),
        sourceId: "123"
    )
}
