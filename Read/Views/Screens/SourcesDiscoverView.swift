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
    @Environment(AppTheme.self) var theme
    @Environment(SourceManager.self) var sourceManager
    @State private var selected = 0
    @State private var previousSelected = 0

    var body: some View {
        VStack {
            if sourceManager.sources.isEmpty {
                ContentUnavailableView(
                    "No sources",
                    systemImage: "gear.badge",
                    description: Text("Add a source in settings")
                )

            } else {
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
                                         tabItemHeight: 42,
                                         padding: .init(
                                             top: 0,
                                             leading: 8,
                                             bottom: 0,
                                             trailing: 0
                                         ),
                                         indicatorView: {
                                             Rectangle()
                                                 .fill(theme.tintColor)
                                                 .cornerRadius(5)
                                                 .shadow(
                                                     color: .green,
                                                     radius: 10
                                                 )
                                         })
                )
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SourcesDiscoverView()
}
