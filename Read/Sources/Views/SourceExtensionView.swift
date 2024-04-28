//
//  SourceExtensionView.swift
//  Read
//
//  Created by Mirna Olvera on 3/31/24.
//

import SwiftUI

struct SRHomeSection {
    var id: String
    var title: String
    var items: [PartialSourceBook]
    var containsMoreItems: Bool
}

struct SourceExtensionView: View {
    @Environment(SourceManager.self) private var sourceManager
    @State var extensionJS: SourceExtension?

    @State var sections: [String: SRHomeSection] = [:]
    @State var fetching = false

    let source: Source

    init(source: Source) {
        self.source = source
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            // MARK: Home

            if source.sourceInfo.interfaces.homePage == true {
                LazyVStack {
                    ForEach(sections.sorted(by: { $0.value.title < $1.value.title }), id: \.value.id) { _, section in
                        SourceSectionView(
                            title: section.title,
                            containsMoreItems: section.containsMoreItems,
                            items: section.items,
                            sourceId: source.id,
                            id: section.id,
                            isLoading: false
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
            if fetching {
                return
            }

            fetching = true

            Task {
                await getHomePageSections()
            }
        }
    }

    func getHomePageSections() async {
        extensionJS = sourceManager.extensions[source.id]

        guard let extensionJS, source.sourceInfo.interfaces.homePage == true else {
            return
        }

        if extensionJS.loaded == false {
            _ = extensionJS.initialiseSource()
        }

        extensionJS.getHomePageSections { result in
            switch result {
            case .success(let homeSection):
                DispatchQueue.main.async {
                    sections[homeSection.id] = SRHomeSection(
                        id: homeSection.id,
                        title: homeSection.title,
                        items: homeSection.items,
                        containsMoreItems: homeSection.containsMoreItems
                    )
                }

            case .failure(let failure):
                //
                Log("Failed to get home sections")
            }
        }
    }
}

// @Observable
// class ObservableHomeSection: Identifiable {
//    var title: String
//    var id: String
//    var containsMoreItems: Bool
//    var items = [PartialSourceBook]()
//    var isLoading = false
//
//    init(title: String, id: String, containsMoreItems: Bool, items: [PartialSourceBook] = [PartialSourceBook](), isLoading: Bool = false) {
//        self.title = title
//        self.id = id
//        self.containsMoreItems = containsMoreItems
//        self.isLoading = isLoading
//        self.items = items
//    }
// }
//
// struct SourceExtensionView: View {
//    @Environment(SourceManager.self) private var sourceManager
//    @State var extensionJS: SourceExtension?
//
//    @State var sections: [String: ObservableHomeSection] = [:]
//    @State var fetching = false
//
//    let source: Source
//
//    init(source: Source) {
//        self.source = source
//    }
//
//    var body: some View {
//        ScrollView(showsIndicators: false) {
//            // MARK: Home
//
//            if source.sourceInfo.interfaces.homePage == true {
//                LazyVStack {
//                    ForEach(sections.sorted(by: { $0.value.title < $1.value.title }), id: \.value.id) { _, section in
//                        SourceSectionView(
//                            title: section.title,
//                            containsMoreItems: section.containsMoreItems,
//                            items: section.items,
//                            sourceId: source.id,
//                            id: section.id,
//                            isLoading: section.isLoading
//                        )
//                    }
//                }
//                .transition(.opacity.combined(with: .scale))
//
//            } else {
//                ContentUnavailableView(
//                    "Source has no homepage",
//                    systemImage: "exclamationmark.triangle",
//                    description: Text("Use search instead")
//                )
//            }
//        }
//        .contentMargins(.vertical, 24, for: .scrollContent)
//        .task {
//            if fetching {
//                return
//            }
//
//            fetching = true
//
//            Task {
//                await getHomePageSections()
//            }
//        }
//    }
//
//    func getHomePageSections() async {
//        Log("\(#function) - got called")
//
//        extensionJS = sourceManager.extensions[source.id]
//
//        guard let extensionJS, source.sourceInfo.interfaces.homePage == true else {
//            return
//        }
//
//        if extensionJS.loaded == false {
//            _ = extensionJS.initialiseSource()
//        }
//
//        let fetchedItems = sections.values.filter {
//            $0.items.count > 0
//        }
//
//        if fetchedItems.count > 0 {
//            return
//        }
//
//        var holdSections: [String: ObservableHomeSection] = [:]
//        var homeSectionsInitialized = 0
//        var homeSectionsItemsAdded = 0
//
//        extensionJS.getHomePageSections { result in
//
//            switch result {
//            case .success(let homeSection):
//                if let section = holdSections[homeSection.id], section.items.isEmpty {
//                    holdSections[homeSection.id]?.items = homeSection.items
//                    section.isLoading = false
//                    homeSectionsItemsAdded += 1
//                } else {
//                    let newSection = ObservableHomeSection(
//                        title: homeSection.title,
//                        id: homeSection.id,
//                        containsMoreItems: homeSection.containsMoreItems
//                    )
//                    homeSectionsInitialized += 1
//                    holdSections[homeSection.id] = newSection
//
//                    let titleSection = ObservableHomeSection(
//                        title: homeSection.title,
//                        id: homeSection.id,
//                        containsMoreItems: homeSection.containsMoreItems,
//                        isLoading: true
//                    )
//
//                    DispatchQueue.main.async {
//                        self.sections[homeSection.id] = titleSection
//                    }
//                }
//
//                if homeSectionsInitialized == homeSectionsItemsAdded {
//                    let sendableHoldSections = holdSections
//
//                    DispatchQueue.main.async {
//                        for (_, (key, elem)) in sendableHoldSections.enumerated() {
//                            self.sections[key] = elem
//                        }
//                    }
//                }
//            case .failure:
//
//                // TODO: ERROR
//                break
//            }
//        }
//    }
// }

#Preview {
    if let source = try? Source(url: URL(string: "")!) {
        return SourceExtensionView(source: source)
    } else {
        return EmptyView()
    }
}
