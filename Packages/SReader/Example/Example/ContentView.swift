//
//  ContentView.swift
//  Example
//
//  Created by Mirna Olvera on 5/18/24.
//

import SReader
import SwiftUI

struct Reader: View {
    @Environment(\.dismiss) var dismiss

    @State var viewModel: EBookReaderViewModel
    @State var showContentSheet = false

    init(
        file: URL
    ) {
        self._viewModel = State(initialValue: EBookReaderViewModel(file: file))
    }

    var body: some View {
        VStack {
            EBookReader(viewModel: viewModel)
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
            .listStyle(.plain)

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

struct ContentView: View {
    @State var show = false

    var body: some View {
        NavigationStack {
            NavigationLink {
                Reader(file: TEST_EPUB_URL!)
            } label: {
                Label("Go", systemImage: "book")
            }
            .tabItem {
                Text("1")
            }

            NavigationLink {
                PDFReader(file: TEST_PDF_URL!)
            } label: {
                Label("pdf", systemImage: "book")
            }
            .tabItem {
                Text("2")
            }
        }
    }
}

#Preview {
    ContentView()
}
