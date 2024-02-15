//
//  EBookReaderContent.swift
//  Read
//
//  Created by Mirna Olvera on 2/12/24.
//

import SwiftUI

struct EBookReaderContent: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EBookReaderViewModel

    @State private var loading = true
    @State private var tocError = false

    var body: some View {
        if loading {
            ZStack {
                Color.black
                ProgressView()
            }
            .onAppear {
                if viewModel.bookToc != nil {
                    loading = false
                    return
                }

                let script = """
                function flattenTocItems(items) {
                  const flattenedItems = []

                  function flatten(item, depth) {
                    const flattenedItem = {
                      href: item.href,
                      id: item.id,
                      label: item.label,
                      depth: depth
                    }

                    flattenedItems.push(flattenedItem)

                    if (item.subitems && item.subitems.length > 0) {
                      item.subitems.forEach(subitem => flatten(subitem, depth + 1))
                    }
                  }

                  items.forEach(item => flatten(item, 0))

                  return flattenedItems
                }

                JSON.stringify(flattenTocItems(globalReader?.book.toc));
                """

                viewModel.webView.evaluateJavaScript(script) { success, error in
                    if let content = success as? String {
                        if let data = content.data(using: .utf8) {
                            do {
                                viewModel.bookToc = try JSONDecoder().decode([TocItem].self, from: data)
                            } catch {
                                print("Failed to decode: \(error.localizedDescription)")
                            }
                        } else {
                            print("Couldnt convert tocString to data")
                        }

                    } else {
                        print("ERROR: \(error?.localizedDescription ?? "")")
                        tocError = true
                    }

                    withAnimation {
                        loading = false
                    }
                }
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    HStack {
                        Text("Contents")
                            .font(.title)

                        Spacer()

                        Button("Done") {
                            dismiss()
                        }
                        .foregroundStyle(Color.accent)
                    }
                    .padding(.horizontal)

                    if tocError == false {
                        ForEach(viewModel.bookToc ?? []) { chapter in
                            let selected = viewModel.relocateDetails?.tocItem.id == chapter.id
                            let depth = chapter.depth

                            VStack {
                                Button {
                                    viewModel.setReaderPosistion(cfi: chapter.href)
                                } label: {
                                    HStack {
                                        Text(chapter.label)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundStyle(selected ? Color.accent : .white)
                                    .fontWeight(depth == 0 ? .bold : .light)
                                }
                                .padding(.leading, CGFloat(depth) * 10)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .id(chapter.id)
                        }

                    } else {
                        Text("ERROR NO TOC")
                    }
                }
                .onAppear {
                    proxy.scrollTo(viewModel.relocateDetails?.tocItem.id)
                }
            }
            .padding(.top, 12)
            .background(.black)
        }
    }
}

#Preview {
    EBookReaderContent(viewModel: EBookReaderViewModel())
}
