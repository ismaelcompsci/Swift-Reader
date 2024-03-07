//
//  SwiftUIView.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

struct PDFReader: View {
    @StateObject var viewModel: PDFViewModel
    let url: URL

    init(viewModel: PDFViewModel, url: URL) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.url = url
    }

    init(url: URL) {
        self._viewModel = StateObject(wrappedValue: PDFViewModel(pdfFile: url))
        self.url = url
    }

    var body: some View {
        PDFKitView(viewModel: viewModel)
            .onAppear {
                guard let pageIndex = viewModel.pdfInitialPageIndex else {
                    let page = viewModel.pdfDocument.outlineRoot?.child(at: 0)?.destination?.page

                    viewModel.currentPage = page
                    viewModel.currentLabel = page?.label ?? ""

                    return
                }

                let page = viewModel.pdfDocument.page(at: pageIndex)
                viewModel.currentPage = page
                viewModel.currentLabel = page?.label ?? ""
                viewModel.goTo(pageIndex: pageIndex)
            }
    }
}

#Preview {
    PDFReader(url: URL(string: "")!)
}
