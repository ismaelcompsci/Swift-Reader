//
//  PDFReader.swift
//  Read
//
//  Created by Mirna Olvera on 5/31/24.
//

import SReader
import SwiftUI

struct PDFReader: View {
    @Environment(\.dismiss) var dismiss

    var book: SDBook
    @State var viewModel: PDFReaderViewModel
    @State var showOverlay = false
    @State var showSettings = false
    @State var showContent = false

    init(book: SDBook) {
        self.book = book
        if let path = book.fullPath {
            _viewModel = State(
                initialValue: PDFReaderViewModel(
                    file: path,
                    initialLocation: book.position?.toSRLocater()
                )
            )
        } else {
            _viewModel = State(initialValue: PDFReaderViewModel(file: URL(string: "none")!))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()

                if showOverlay {
                    Text(viewModel.currentLocation?.title ?? "N/A")
                        .font(.footnote)
                        .lineLimit(1)
                        .foregroundStyle(viewModel.theme.fg.color.opacity(0.5))
                        .offset(x: 24 / 2)

                } else {
                    Text(book.title)
                        .font(.footnote)
                        .lineLimit(1)
                        .foregroundStyle(viewModel.theme.fg.color.opacity(0.5))
                }

                Spacer()

                if showOverlay {
                    SRXButton {
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(maxHeight: 34)

            SRPDFReader(viewModel: viewModel)

            HStack {
                Spacer()

                Text("\((viewModel.currentLocation?.locations.totalProgression ?? 0) * 100, specifier: "%.0f")%")
                    .font(.footnote)
                    .lineLimit(1)
                    .foregroundStyle(viewModel.theme.fg.color.opacity(0.5))

                Spacer()
            }
        }
        .overlay {
            if viewModel.state == .loading {
                ZStack {
                    viewModel.theme.bg.color

                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay {
            ReaderSettingsButton(
                show: $showOverlay,
                progress: viewModel.currentLocation?.locations.totalProgression ?? 0,
                onEvent: settingsButtonHandler
            )
        }
        .background(viewModel.theme.bg.color)
        .task {
            let highlights = book.highlights.map { $0.toSRHiglight() }

            viewModel.start(highlights: highlights)

            book.lastOpened = .now
        }
        .onReceive(viewModel.onRelocated, perform: book.update)
        .onReceive(viewModel.onHighlighted, perform: book.highlighted)
        .onReceive(viewModel.onRemovedHighlight, perform: book.unhighlighted)
        .onReceive(viewModel.onTap, perform: { _ in
            withAnimation {
                showOverlay.toggle()
            }
        })
        .sheet(isPresented: $showSettings, content: {
            ReaderSettings(bookTheme: $viewModel.theme, isPDF: true, updateTheme: viewModel.setTheme)
        })
        .sheet(isPresented: $showContent) {
            ReaderContent(
                currentTocItem: viewModel.currentTocLink,
                tocItems: viewModel.flattenedToc,
                onTocItemPress: tocItemPressedHandler
            )
        }
    }

    private func settingsButtonHandler(_ action: ReaderSettingsAction) {
        switch action {
        case .content:
            showContent = true
//        case .bookmarks:
//            break
        case .settings:
            showSettings = true
        }
    }

    private func tocItemPressedHandler(_ link: SRLink) {
        viewModel.goTo(for: link)
    }
}
