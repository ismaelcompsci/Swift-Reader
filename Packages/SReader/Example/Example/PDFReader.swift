//
//  PDFReader.swift
//  Example
//
//  Created by Mirna Olvera on 5/22/24.
//

import PDFKit
import SReader
import SwiftUI

struct PDFReader: View {
    @Environment(\.dismiss) var dismiss

    @State var viewModel: PDFReaderViewModel
    @State var showContentSheet = false

    init(
        file: URL
    ) {
        self._viewModel = State(
            initialValue: PDFReaderViewModel(
                file: file
            )
        )
    }

    var body: some View {
        VStack {
            PDFKitView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.start()
        }
        .sheet(isPresented: $showContentSheet, content: {
            List {
                ForEach(viewModel.toc.indices, id: \.self) { index in
                    let item = viewModel.toc[index]

                    Button {
                        viewModel.goTo(for: item)
                        showContentSheet.toggle()
                    } label: {
                        HStack {
                            Text(item.title ?? "")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(.gray)
                        }
                    }
                    .tint(.primary)
                }
            }

        })
        .navigationBarBackButtonHidden(true)
        .overlay {
            VStack {
                HStack {
                    if let title = viewModel.currentLocation?.title {
                        Text(title)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                Spacer()
                HStack {
                    Button {
                        showContentSheet = true

                    } label: {
                        Image(systemName: "list.dash")
                    }

                    Button {
                        viewModel.highlightSelection()
                    } label: {
                        Image(systemName: "highlighter")
                    }

                    Button {
                        if let l = viewModel.currentLocation {
                            viewModel.goTo(for: l)
                        }
                    } label: {
                        Image(systemName: "scribble.variable")
                    }

                    if let progress = viewModel.currentLocation?.locations.totalProgression {
                        Text("\(Int(progress * 100))%")
                    }
                }
            }
        }
        .overlay {
            switch viewModel.state {
            case .loading:
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    ProgressView()
                }

            case .ready:
                EmptyView()
            case .error:
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    VStack {
                        Text("Something went wrong")

                        Button("Return") {}
                    }
                }
            }
        }
    }
}
