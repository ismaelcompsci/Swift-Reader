//
//  EBookReader.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

struct EBookReader: View {
    @StateObject var viewModel: EBookReaderViewModel
    let url: URL

    init(viewModel: EBookReaderViewModel, url: URL) {
        self.url = url
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init(url: URL) {
        self.url = url
        _viewModel = StateObject(wrappedValue: EBookReaderViewModel(file: url, delay: .milliseconds(500)))
    }

    var body: some View {
        EBookWebView(viewModel: viewModel)
            .onChange(of: viewModel.canStartReader) { oldValue, newValue in
                if oldValue == false, newValue == true {
                    Task {
                        await viewModel.startReader()
                    }
                }
            }
//            .onChange(of: viewModel.allDone) { oldValue, newValue in
//                if oldValue == false, newValue == true {
//                    viewModel.currentLabel = viewModel.currentLocation?.tocItem?.label ?? "..."
//                }
//            }
    }
}

#Preview {
    EBookReader(url: URL(string: "")!)
}
