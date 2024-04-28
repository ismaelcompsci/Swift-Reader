//
//  ScrollableTabBar.swift
//  Read
//
//  Created by Mirna Olvera on 4/22/24.
//

import SwiftUI

struct ScrollableTabBar<Content: View>: View {
    @Binding var tabs: [Tab]
    @Binding var activeTab: Tab.ID

    @State private var tabBarScrollState: Tab.ID
    @State private var mainViewScrollState: Tab.ID?
    @State private var progress: CGFloat = .zero

    private var content: (CGSize) -> Content

    init(
        tabs: Binding<[Tab]>,
        activeTab: Binding<Tab.ID>,
        content: @escaping (CGSize) -> Content
    ) {
        self._tabs = tabs
        self._activeTab = activeTab
        self._tabBarScrollState = State(initialValue: activeTab.wrappedValue)
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomTabBar()

            GeometryReader {
                let size = $0.size

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        content(size)
                    }
                    .scrollTargetLayout()
                    .rect { rect in
                        progress = -rect.minX / size.width
                    }
                }
                .scrollPosition(id: $mainViewScrollState)
                .scrollTargetBehavior(.paging)
                .onChange(of: mainViewScrollState) { _, newValue in
                    if let newValue = newValue {
                        withAnimation(.snappy) {
                            tabBarScrollState = newValue
                            activeTab = newValue
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func CustomTabBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(tabs) { tab in
                    Button {
                        withAnimation(.snappy) {
                            activeTab = tab.id
                            tabBarScrollState = tab.id
                            mainViewScrollState = tab.id
                        }
                    } label: {
                        Text(tab.label)
                            .padding(.vertical, 12)
                            .contentShape(.rect)
                            .foregroundStyle(activeTab == tab.id ? Color.primary : Color.gray)
                    }
                    .buttonStyle(.plain)
                    .rect { rect in
                        tab.update(size: rect.size)
                        tab.update(minX: rect.minX)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .overlay(alignment: .bottom) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)

                let inputRange = tabs.indices.compactMap { CGFloat($0) }
                let outputRange = tabs.compactMap { $0.size.width }

                let outputPositionRange = tabs.compactMap { $0.minX }
                let indicatorPosition = progress.interpolate(
                    inputRange: inputRange,
                    outputRange: outputPositionRange
                )

                let indicatorWidth = progress.interpolate(
                    inputRange: inputRange,
                    outputRange: outputRange
                )

                Rectangle()
                    .fill(.red)
                    .frame(width: indicatorWidth, height: 1.5)
                    .offset(x: indicatorPosition)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .scrollPosition(
            id: .init(get: {
                tabBarScrollState
            }, set: { _ in
            }),
            anchor: .center
        )
    }
}

@Observable class Tab: Identifiable {
    private(set) var id: Tab.ID
    var label: String
    var size: CGSize = .zero
    var minX: CGFloat = .zero

    public typealias ID = String

    init(id: Tab.ID, label: String) {
        self.id = id
        self.label = label
    }

    func update(size: CGSize) {
        self.size = size
    }

    func update(minX: CGFloat) {
        self.minX = minX
    }
}

extension CGFloat {
    func interpolate(inputRange: [CGFloat], outputRange: [CGFloat]) -> CGFloat {
        let x = self
        let length = inputRange.count - 1
        if x <= inputRange[0] || length == 0 { return outputRange[0] }

        for index in 1 ... length {
            let x1 = inputRange[index - 1]
            let x2 = inputRange[index]

            let y1 = outputRange[index - 1]
            let y2 = outputRange[index]

            if x <= inputRange[index] {
                let y = y1 + ((y2 - y1) / (x2 - x1)) * (x - x1)

                return y
            }
        }

        return outputRange[length]
    }
}
