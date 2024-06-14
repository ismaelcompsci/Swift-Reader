//
//  SwiftUIView.swift
//
//
//  Created by Mirna Olvera on 5/30/24.
//

import SwiftUI

public struct SRPDFReader: View {
    @State var viewModel: PDFReaderViewModel

    public init(viewModel: PDFReaderViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        PDFKitView(viewModel: viewModel)
    }
}
