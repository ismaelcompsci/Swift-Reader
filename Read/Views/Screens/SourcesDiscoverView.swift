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

    @State var tabs: [Tab] = []
    @State var activeTab: Tab.ID = ""

    var body: some View {
        VStack {
            if sourceManager.sources.isEmpty {
                ContentUnavailableView(
                    "No sources",
                    systemImage: "gear.badge",
                    description: Text("Add a source in settings")
                )

            } else {
                if tabs.isEmpty == false && activeTab != "" {
                    ScrollableTabBar(
                        tabs: $tabs,
                        activeTab: $activeTab
                    ) { size in
                        ForEach(sourceManager.sources) { source in

                            SourceExtensionView(source: source)
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
            tabs = sourceManager.sources.map {
                Tab(
                    id: $0.id,
                    label: $0.sourceInfo.name
                )
            }

            activeTab = tabs[0].id
        }
    }
}

#Preview {
    SourcesDiscoverView()
}
