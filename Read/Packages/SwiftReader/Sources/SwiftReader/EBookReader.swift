//
//  EBookReader.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

public struct EBookReader: View {
    @StateObject var viewModel: EBookReaderViewModel
    let url: URL?

    public init(viewModel: EBookReaderViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.url = nil
    }

    public init(url: URL) {
        self.url = url
        _viewModel = StateObject(wrappedValue: EBookReaderViewModel(file: url, delay: .milliseconds(500)))
    }

    public var body: some View {
        EBookWebView(viewModel: viewModel)
            .onChange(of: viewModel.allDone) { oldValue, newValue in
                if oldValue == false, newValue == true {
                    viewModel.state = .done
                    viewModel.currentLabel = viewModel.currentLocation?.tocItem?.label ?? "..."
                }
            }
    }
}

#Preview {
    EBookReader(url: URL(string: "")!)
}
