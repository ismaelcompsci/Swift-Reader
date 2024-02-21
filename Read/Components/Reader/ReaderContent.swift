//
//  ReaderContent.swift
//  Read
//
//  Created by Mirna Olvera on 2/16/24.
//

import SwiftUI

struct ReaderContent: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ReaderViewModel

    var body: some View {
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
                
                ForEach(viewModel.toc ?? []) { tocItem in
                    let selected = viewModel.isBookTocItemSelected(item: tocItem)
                    
                    VStack {
                        Button {
                            if viewModel.isPDF {
                                if let page = tocItem.outline?.destination?.page {
                                    viewModel.pdfView?.go(to: page)
                                }
                            } else {
                                viewModel.goTo(cfi: tocItem.href)
                            }
                            
                            viewModel.showContentSheet.toggle()
                        } label: {
                            HStack {
                                if viewModel.isPDF {
                                    Text(tocItem.outline?.label ?? "")
                                } else {
                                    Text(tocItem.label ?? "")
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(selected ? Color.accent : .white)
                            .fontWeight(tocItem.depth == 0 ? .bold : .light)
                        }
                        .padding(.leading, CGFloat(tocItem.depth) * 10)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .id(tocItem.id)
                }
            }
            .onAppear {
                value.scrollTo(viewModel.currentTocItem?.id)
            }
        }
    }
}

#Preview {
    ReaderContent(viewModel: ReaderViewModel(url: URL(string: "")!, highlights: []))
}
