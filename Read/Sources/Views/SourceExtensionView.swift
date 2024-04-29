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
    var fetching = false

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
                        self.sections[srhomeSection.id] = srhomeSection
                    }
                }

                if self.homeSectionsInitialized == self.homeSectionsWithItemsAdded {
                    let sendableHoldSections = self.batchUpdateHomeSections

                    DispatchQueue.main.async {
                        self.sections = sendableHoldSections
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

    let sourceId: String
    let hasHomePageInterface: Bool

    init(sourceId: String, hasHomePageInterface: Bool, extensionJS: SRExtension?) {
        self.sourceId = sourceId
        self.hasHomePageInterface = hasHomePageInterface
        self.extensionJS = extensionJS

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
                    }
                }
                .transition(.opacity.combined(with: .scale))

            } else {
                ContentUnavailableView(
                    "Source has no homepage",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Use search instead")
                )
            }
        }
        .contentMargins(.vertical, 24, for: .scrollContent)
        .task {
            guard let homeSectionProvider = homeSectionProvider, hasHomePageInterface == true else { return }

            if homeSectionProvider.fetching {
                return
            }

            homeSectionProvider.fetching = true

            homeSectionProvider.getHomePageSections()
        }
    }
}

#Preview {
    SourceExtensionView(sourceId: "", hasHomePageInterface: false, extensionJS: nil)
}
