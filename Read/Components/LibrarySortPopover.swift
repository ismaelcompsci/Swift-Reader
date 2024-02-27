//
//  LibrarySortPopover.swift
//  Read
//
//  Created by Mirna Olvera on 2/2/24.
//

import SwiftUI

enum LibrarySortKeys: String, CaseIterable {
    case title = "Title"
    case date = "Date"
    case author = "Author"
    case last_read = "Last Read"
    case progress = "Progress"
}

enum LibrarySortOrder: String {
    case ascending
    case descending
}

struct LibrarySortPopover: View {
    @EnvironmentObject var appColor: AppColor

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
            .popover(isPresented: $sortPopoverShowing, attachmentAnchor: .rect(.bounds),
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
            .foregroundStyle(appColor.accent)
        }
    }
}

#Preview {
    LibrarySortPopover(selectedSortKey: .constant(.title), selectedSortOrder: .constant(.descending))
}
