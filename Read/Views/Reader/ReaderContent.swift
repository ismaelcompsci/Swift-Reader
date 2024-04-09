//
//  ReaderContent.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftReader
import SwiftUI

struct ReaderContent<T: TocItem>: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme

    var toc: [T]
    var isSelected: ((T) -> Bool)?
    var tocItemPressed: ((T) -> Void)?
    var currentTocItemId: Int?

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(toc) { tocItem in
                            let selected = isSelected?(tocItem) ?? false

                            VStack {
                                Button {
                                    tocItemPressed?(tocItem)

                                } label: {
                                    HStack {
                                        Text(tocItem.label)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                            .fontWeight(tocItem.depth == 0 ? .semibold : .light)

                                        Spacer()

                                        if let pageNumber = tocItem.pageNumber {
                                            Text("\(pageNumber)")
                                        }
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundStyle(selected ? theme.tintColor : .white)
                                }
                                .padding(.leading, CGFloat(tocItem.depth ?? 0) * 10)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .id(tocItem.id)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    if let currentTocItemId {
                        proxy.scrollTo(currentTocItemId, anchor: .center)
                    }
                }
            }
            .navigationTitle("Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SRXButton {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ReaderContent(toc: [PDFTocItem(outline: nil, depth: 4)])
}
