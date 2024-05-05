//
//  ScrollableTabBar.swift
//  Read
//
//  Created by Mirna Olvera on 4/22/24.
//

import SwiftUI
import SwiftUIIntrospect
import UIKit

@Observable
class ScrollViewDelegate: NSObject, UIScrollViewDelegate {
    var isScrolling = false

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isScrolling == false {
            isScrolling = true
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrolling = false
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isScrolling = false
    }
}

struct ScrollableTabBarScrollingState: Equatable, Identifiable {
    var id = UUID()
    var isScrolling: Bool
    var activeTab: Tab.ID

    static func ==(
        lhs: ScrollableTabBarScrollingState,
        rhs: ScrollableTabBarScrollingState
    ) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ScrollableTabBar<Content: View>: View {
    @Binding var tabs: [Tab]
    @Binding var state: ScrollableTabBarScrollingState

    @State private var tabBarScrollState: Tab.ID
    @State private var mainViewScrollState: Tab.ID?
    @State private var progress: CGFloat = .zero
    @State private var scrollViewDelegate = ScrollViewDelegate()

    private var content: (CGSize) -> Content

    init(
        tabs: Binding<[Tab]>,
        state: Binding<ScrollableTabBarScrollingState>,
        content: @escaping (CGSize) -> Content
    ) {
        self._tabs = tabs
        self._state = state
        self._tabBarScrollState = State(initialValue: state.wrappedValue.activeTab)
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
                            state.activeTab = newValue
                            tabBarScrollState = newValue
                        }
                    }
                }
                .onChange(of: scrollViewDelegate.isScrolling) { _, newValue in
                    if newValue == false {
                        let index = Int(progress)
                        let tab = tabs[index]

                        withAnimation(.snappy) {
                            state = .init(isScrolling: newValue, activeTab: tab.id)
                            tabBarScrollState = tab.id
                        }
                    }
                }
                .introspect(.scrollView, on: .iOS(.v17)) { scrollView in
                    scrollView.delegate = scrollViewDelegate
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
                            state = .init(isScrolling: false, activeTab: tab.id)
                            tabBarScrollState = tab.id
                            mainViewScrollState = tab.id
                        }
                    } label: {
                        Text(tab.label)
                            .padding(.vertical, 12)
                            .contentShape(.rect)
                            .foregroundStyle(state.activeTab == tab.id ? Color.primary : Color.gray)
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
