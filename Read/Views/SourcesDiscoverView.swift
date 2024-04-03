//
//  SourcesDiscoverView().swift
//  Read
//
//  Created by Mirna Olvera on 3/28/24.
//

import NukeUI
import PagerTabStripView
import SwiftData
import SwiftUI

struct SourcesDiscoverView: View {
    @Environment(SourceManager.self) var sourceManager
    @State private var selected = 0
    @State private var previousSelected = 0

    var body: some View {
        VStack {
            PagerTabStripView(swipeGestureEnabled: .constant(true), selection: $selected) {
                ForEach(sourceManager.sources.indices, id: \.self) { index in
                    let source = sourceManager.sources[index]

                    Group {
                        if selected == index || previousSelected == index {
                            SourceExtensionView(source: source)
                                .transition(.opacity)
                                .animation(.easeInOut, value: selected == index)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .pagerTabItem(tag: index) {
                        Text("\(source.sourceInfo.name)")
                    }
                }
            }
            .onChange(of: selected) { oldValue, newValue in
                previousSelected = oldValue
                selected = newValue
            }
            .pagerTabStripViewStyle(
                .scrollableBarButton(tabItemSpacing: 15,
                                     tabItemHeight: 28,
                                     padding: .init(
                                         top: 0,
                                         leading: 8,
                                         bottom: 0,
                                         trailing: 0
                                     ),
                                     indicatorView: {
                                         Rectangle().fill(Color.accent).cornerRadius(5)
                                     })
            )
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SourcesDiscoverView()
}
