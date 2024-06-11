//
//  SwiftUIView.swift
//
//
//  Created by Mirna Olvera on 5/30/24.
//

import SwiftUI

public struct EBookReader: View {
    @State var viewModel: EBookReaderViewModel

    public init(viewModel: EBookReaderViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        EBookWebView(viewModel: viewModel)
    }
}
