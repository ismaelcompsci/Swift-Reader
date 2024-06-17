//
//  ReaderContent.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SReader
import SwiftUI

struct ReaderContent: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme

    var currentTocItem: SRLink?
    var tocItems: [(level: Int, link: SRLink)]
    var onTocItemPress: (SRLink) -> Void

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(tocItems.enumerated()), id: \.offset) { _, item in
                        let level = item.level
                        let link = item.link

                        let selected = link.title == currentTocItem?.title

                        Button {
                            onTocItemPress(link)
                            dismiss()
                        } label: {
                            ContentRow(item: link)
                        }
                        .listRowInsets(.init(top: 10, leading: 20 + (Double(level) * 10), bottom: 10, trailing: 20))
                        .listRowBackground(
                            selected ? Color(uiColor: UIColor.tertiarySystemBackground) : nil
                        )
                        .id(link.title ?? "")
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Content")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        SRXButton {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo(currentTocItem?.title, anchor: .center)
                }
            }
        }
    }
}

extension ReaderContent {
    struct ContentRow: View {
        let item: SRLink

        var body: some View {
            Text(item.title ?? "Unknown")
                .lineLimit(1)
        }
    }
}

#Preview {
    ReaderContent(
        tocItems: [
            (0, SRLink(href: "1", title: "Chapter One")),
            (0, SRLink(href: "2", title: "Chapter Two")),
            (0, SRLink(href: "3", title: "Chapter Three")),
            (0, SRLink(href: "4", title: "Chapter Four")),
        ], onTocItemPress: { _ in }
    )
    .environment(AppTheme.shared)
}
