//
//  ReaderContent.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

struct ReaderContent<T: TocItem>: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appColor: AppColor

    var toc: [T]
    var isSelected: ((T) -> Bool)?
    var tocItemPressed: ((T) -> Void)?
    var currentTocItemId: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                HStack {
                    Text("Contents")
                        .font(.setCustom(fontStyle: .title, fontWeight: .bold))
                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(appColor.accent)
                }
                .padding(.horizontal)
                .padding(.vertical)

                ForEach(toc) { tocItem in
                    let selected = isSelected?(tocItem) ?? false

                    VStack {
                        Button {
                            tocItemPressed?(tocItem)

                        } label: {
                            HStack {
                                Text(tocItem.label)

                                Spacer()

                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(selected ? appColor.accent : .white)
                            .fontWeight(tocItem.depth == 0 ? .semibold : .light)
                        }
                        .padding(.leading, CGFloat(tocItem.depth ?? 0) * 10)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .id(tocItem.id)
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                if let currentTocItemId {
                    proxy.scrollTo(currentTocItemId)
                }
            }
        }
    }
}

#Preview {
    ReaderContent(toc: [PDFTocItem(outline: nil, depth: 4)])
}
