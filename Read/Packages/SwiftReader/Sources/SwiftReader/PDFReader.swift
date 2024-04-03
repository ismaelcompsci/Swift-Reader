//
//  SwiftUIView.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

public struct PDFReader: View {
    @StateObject var viewModel: PDFViewModel
    let url: URL

    public init(viewModel: PDFViewModel, url: URL) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.url = url
    }

    public init(url: URL) {
        self._viewModel = StateObject(wrappedValue: PDFViewModel(pdfFile: url))
        self.url = url
    }

    public var body: some View {
        PDFKitView(viewModel: viewModel)
            .onAppear {
                guard let pageIndex = viewModel.pdfInitialPageIndex else {
                    return
                }

                viewModel.goTo(pageIndex: pageIndex)
            }
    }
}

#Preview {
    PDFReader(url: URL(string: "")!)
}
