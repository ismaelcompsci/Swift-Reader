//
//  SourcesDiscoverView().swift
//  Read
//
//  Created by Mirna Olvera on 3/28/24.
//

import NukeUI
import SwiftData
import SwiftUI

struct SourcesDiscoverView: View {
    @Environment(AppTheme.self) var theme
    @Environment(SourceManager.self) var sourceManager

    @State var tabs: [Tab] = []
    @State var tabBarState = ScrollableTabBarScrollingState(isScrolling: false, activeTab: "")

    var body: some View {
        VStack {
            if sourceManager.sources.isEmpty {
                ContentUnavailableView(
                    "No sources",
                    systemImage: "gear.badge",
                    description: Text("Add a source in settings")
                )

            } else {
                if tabs.isEmpty == false && tabBarState.activeTab != "" {
                    ScrollableTabBar(
                        tabs: $tabs,
                        state: $tabBarState
                    ) { size in
                        ForEach(sourceManager.sources) { source in

                            SourceExtensionView(
                                sourceId: source.id,
                                hasHomePageInterface: source.sourceInfo.interfaces.homePage,
                                extensionJS: sourceManager.extensions[source.id],
                                tabBarState: $tabBarState
                            )
                            .frame(width: size.width, height: size.height)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            tabs = sourceManager.sources.map { source in
                Tab(
                    id: source.id,
                    label: source.sourceInfo.name,
                    size: tabs.first(where: { tab in tab.id == source.id })?.size ?? .zero,
                    minX: tabs.first(where: { tab in tab.id == source.id })?.minX ?? .zero
                )
            }

            if tabs.isEmpty == false {
                tabBarState = .init(isScrolling: false, activeTab: tabs[0].id)
            }
        }
    }
}

#Preview {
    SourcesDiscoverView()
}
