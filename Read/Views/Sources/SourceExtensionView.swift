//
//  SourceExtensionView.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import OSLog
import SwiftUI

struct SourceExtensionView: View {
    @Environment(SourceManager.self) private var sourceManager

    @State var homeSectionProvider: HomeSectionProvider
    @Binding var tabBarState: ScrollableTabBarScrollingState

    var extensionJS: SRExtension
    let sourceId: String
    let hasHomePageInterface: Bool

    init(
        sourceId: String,
        hasHomePageInterface: Bool,
        extensionJS: SRExtension,
        tabBarState: Binding<ScrollableTabBarScrollingState>
    ) {
        self.sourceId = sourceId
        self.hasHomePageInterface = hasHomePageInterface
        self.extensionJS = extensionJS
        self._tabBarState = tabBarState
        self._homeSectionProvider = State(initialValue: HomeSectionProvider(extensionJS: extensionJS))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            // MARK: Home

            if hasHomePageInterface == true {
                LazyVStack {
                    ForEach(Array(homeSectionProvider.sections.values).sorted(by: { $0.title < $1.title }), id: \.id) { section in
                        SourceSectionView(section: section, sourceId: sourceId)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.bottom, 74)
                .background()

            } else {
                ContentUnavailableView(
                    "Source has no homepage",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Use search instead")
                )
            }
        }
        .contentMargins(.horizontal, 12, for: .scrollContent)
        .contentMargins(.vertical, 12, for: .scrollContent)
        .refreshable(action: {
            if homeSectionProvider.isLoading == true { return }

            homeSectionProvider.getHomePageSections()
        })
        .onChange(of: tabBarState) { _, newValue in
            getHomePageSection(isScrolling: newValue.isScrolling, activeTab: newValue.activeTab)
        }
    }

    func getHomePageSection(isScrolling: Bool, activeTab: Tab.ID) {
        if isScrolling == false, activeTab == (sourceId as Tab.ID) {
            guard hasHomePageInterface == true else { return }

            if homeSectionProvider.hasFetched {
                return
            }

            homeSectionProvider.hasFetched = true

            Task {
                homeSectionProvider.getHomePageSections()
            }
        }
    }
}

struct SRHomeSection {
    var id: String
    var title: String
    var items: [PartialSourceBook]
    var containsMoreItems: Bool
}

@Observable
class HomeSectionProvider {
    var isLoading = false
    var extensionJS: SRExtension
    var sections: [String: SRHomeSection] = [:]
    var hasFetched = false

    var batchUpdateHomeSections: [String: SRHomeSection] = [:]
    var homeSectionsInitialized = 0
    var homeSectionsWithItemsAdded = 0

    init(extensionJS: SRExtension) {
        self.extensionJS = extensionJS
    }

    func getHomePageSections() {
        isLoading = true
        extensionJS.getHomePageSections { [weak self] result in

            guard let self = self else { return }

            switch result {
            case .success(let homeSection):

                if let batchedHomeSection = self.batchUpdateHomeSections[homeSection.id], batchedHomeSection.items.isEmpty {
                    self.batchUpdateHomeSections[homeSection.id]?.items = homeSection.items
                    self.homeSectionsWithItemsAdded += 1
                } else {
                    let srhomeSection = SRHomeSection(
                        id: homeSection.id,
                        title: homeSection.title,
                        items: homeSection.items,
                        containsMoreItems: homeSection.containsMoreItems
                    )
                    self.homeSectionsInitialized += 1
                    self.batchUpdateHomeSections[srhomeSection.id] = srhomeSection

                    DispatchQueue.main.async {
                        withAnimation(.snappy) {
                            self.sections[srhomeSection.id] = srhomeSection
                        }
                    }
                }

                if self.homeSectionsInitialized == self.homeSectionsWithItemsAdded {
                    let sendableHoldSections = self.batchUpdateHomeSections

                    DispatchQueue.main.async {
                        self.isLoading = false
                        withAnimation(.snappy) {
                            self.sections = sendableHoldSections
                        }
                    }
                }

            case .failure(let error):
                Logger.general.error("Failed to get home sections: \(error.localizedDescription)")
            }
        }
    }
}
