//
//  PDFReaderContent.swift
//  Read
//
//  Created by Mirna Olvera on 2/13/24.
//

import SwiftUI

struct PDFReaderContent: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: PDFReaderViewModel

    @State private var loading = false
    @State private var tocError = false

    var body: some View {
        if loading {
            ZStack {
                Color.black
                ProgressView()
            }
        } else {
            ScrollViewReader { value in
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
                        ForEach(viewModel.pdfToc, id: \.outline) { item in
                            let selected = item.outline.hashValue == viewModel.currenTocItem?.outline.hashValue

                            VStack {
                                Button {
                                    if let page = item.outline.destination?.page {
                                        viewModel.pdfView.go(to: page)
                                    }

                                } label: {
                                    HStack {
                                        Text(item.outline.label ?? "")

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundStyle(selected ? Color.accent : .white)
                                    .fontWeight(item.depth == 0 ? .bold : .light)
                                }
                                .padding(.leading, CGFloat(item.depth) * 10)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .id(item.outline)
                        }

                    } else {
                        Text("ERROR NO TOC")
                    }
                }
                .onAppear {
                    value.scrollTo(viewModel.currenTocItem?.outline)
                }
            }
            .padding(.top, 12)
            .background(.black)
        }
    }
}

#Preview {
    PDFReaderContent(viewModel: PDFReaderViewModel(url: URL(string: "")!))
}
