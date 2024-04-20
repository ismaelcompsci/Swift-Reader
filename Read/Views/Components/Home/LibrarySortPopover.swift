//
//  LibrarySortPopover.swift
//  Read
//
//  Created by Mirna Olvera on 2/2/24.
//

import SwiftUI

struct LibrarySortPopover: View {
    @Environment(AppTheme.self) var theme

    @State var sortPopoverShowing = false

    @Binding var selectedSortKey: LibrarySortKeys
    @Binding var selectedSortOrder: LibrarySortOrder

    var body: some View {
        HStack {
            Spacer()
            Text("Sort By")
            Button {
                sortPopoverShowing.toggle()

            } label: {
                HStack {
                    Text(selectedSortKey.rawValue)
                    if selectedSortOrder == .ascending {
                        Image(systemName: "arrow.up")
                    } else {
                        Image(systemName: "arrow.down")
                    }
                }
            }
            .popover(isPresented: $sortPopoverShowing,
                     content: {
                         VStack(alignment: .leading, spacing: 20) {
                             ForEach(LibrarySortKeys.allCases, id: \.self) { sortKey in
                                 Button {
                                     if selectedSortKey == sortKey {
                                         if selectedSortOrder == .ascending {
                                             selectedSortOrder = .descending
                                         } else {
                                             selectedSortOrder = .ascending
                                         }
                                     } else {
                                         selectedSortOrder = .descending
                                     }

                                     selectedSortKey = sortKey

                                 } label: {
                                     HStack {
                                         Text(sortKey.rawValue)
                                         if selectedSortKey == sortKey && selectedSortOrder == .descending {
                                             Image(systemName: "arrow.down")
                                                 .font(.system(size: 12))
                                         } else if selectedSortKey == sortKey && selectedSortOrder == .ascending {
                                             Image(systemName: "arrow.up")
                                                 .font(.system(size: 12))
                                         }
                                     }
                                     .frame(maxWidth: .infinity, alignment: .leading)
                                 }
                             }
                         }
                         .padding(.vertical, 16)
                         .padding(.horizontal, 16)
                         .frame(width: 200, alignment: .leading)
                         .presentationCompactAdaptation(.popover)

                     })
            .foregroundStyle(theme.tintColor)
        }
    }
}

#Preview {
    LibrarySortPopover(
        selectedSortKey: .constant(.title),
        selectedSortOrder: .constant(
            .descending
        )
    )

    .preferredColorScheme(.dark)
}
