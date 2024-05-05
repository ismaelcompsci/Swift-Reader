//
//  SourceExtensionView.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import OSLog
import SwiftUI

struct SRHomeSection {
    var id: String
    var title: String
    var items: [PartialSourceBook]
    var containsMoreItems: Bool
}

@Observable
class HomeSectionProvider {
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
        // TODO: Batch update ui
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
                        withAnimation(.bouncy.speed(1.6)) {
                            self.sections[srhomeSection.id] = srhomeSection
                        }
                    }
                }

                if self.homeSectionsInitialized == self.homeSectionsWithItemsAdded {
                    let sendableHoldSections = self.batchUpdateHomeSections

                    DispatchQueue.main.async {
                        withAnimation(.bouncy.speed(1.6)) {
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

struct SourceExtensionView: View {
    @Environment(SourceManager.self) private var sourceManager
    var extensionJS: SRExtension?

    @State var homeSectionProvider: HomeSectionProvider?
    @Binding var tabBarState: ScrollableTabBarScrollingState

    let sourceId: String
    let hasHomePageInterface: Bool

    init(
        sourceId: String,
        hasHomePageInterface: Bool,
        extensionJS: SRExtension?,
        tabBarState: Binding<ScrollableTabBarScrollingState>
    ) {
        self.sourceId = sourceId
        self.hasHomePageInterface = hasHomePageInterface
        self.extensionJS = extensionJS
        self._tabBarState = tabBarState

        if let extensionJS = extensionJS {
            self._homeSectionProvider = State(initialValue: HomeSectionProvider(extensionJS: extensionJS))
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            // MARK: Home

            if hasHomePageInterface == true {
                LazyVStack {
                    ForEach(homeSectionProvider?.sections.sorted(by: { $0.value.title < $1.value.title }) ?? [], id: \.value.id) { _, section in
                        SourceSectionView(
                            title: section.title,
                            containsMoreItems: section.containsMoreItems,
                            items: section.items,
                            sourceId: sourceId,
                            id: section.id,
                            isLoading: section.items.isEmpty
                        )
                        .transition(.blurReplace().combined(with: .scale(0, anchor: .bottomTrailing)))
                    }
                }
            } else {
                ContentUnavailableView(
                    "Source has no homepage",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Use search instead")
                )
            }
        }
        .contentMargins(.vertical, 24, for: .scrollContent)
        .onChange(of: tabBarState) { _, newValue in
            getHomePageSection(isScrolling: newValue.isScrolling, activeTab: newValue.activeTab)
        }
    }

    func getHomePageSection(isScrolling: Bool, activeTab: Tab.ID) {
        if isScrolling == false, activeTab == (sourceId as Tab.ID) {
            guard let homeSectionProvider = homeSectionProvider, hasHomePageInterface == true else { return }

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

#Preview {
    SourceExtensionView(
        sourceId: "",
        hasHomePageInterface: false,
        extensionJS: nil,
        tabBarState: .constant(.init(isScrolling: false, activeTab: ""))
    )
}
