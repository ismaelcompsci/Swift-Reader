//
//  EBookReader.swift
//  Read
//
//  Created by Mirna Olvera on 2/4/24.
//

import RealmSwift
import SwiftUI

struct EBookReader: View {
    var realm = try! Realm()
    var book: Book

    @StateObject var viewModel = EBookReaderViewModel()

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color(hex: viewModel.theme.bg.rawValue)
                    .ignoresSafeArea()

                // MARK: Reader WebView

                ReaderWebView(viewModel: viewModel)
                    .onAppear(perform: initializeReader)

                // MARK: Reader Menu

                if viewModel.showMenuOverlay {
                    EBookReaderMenu(book: book, viewModel: viewModel)
                }

                // MARK: Loader

                if viewModel.isLoading || !viewModel.hasRenderedBook {
                    ZStack {
                        Color.black
                        ProgressView()
                    }
                }
            }
        }
        .ignoresSafeArea()
        .background(Color(hex: viewModel.theme.bg.rawValue))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.showContentSheet, content: {
            EBookReaderContent(viewModel: viewModel)
        })
        .onChange(of: viewModel.isLoading) { _, newValue in
            onWebViewDoneLoading(newValue)
        }
        .onChange(of: viewModel.relocateDetails) { _, newValue in
            if let value = newValue {
                relocated(value)
            }
        }
        .onChange(of: viewModel.hasRenderedBook) { _, _ in
            guard let position = book.readingPosition?.epubCfi else {
                print("NO INITIAL POSITION")
                return
            }

            viewModel.setReaderPosistion(cfi: position)
        }
        .sheet(isPresented: $viewModel.showSettingsSheet, content: {
            EBookReaderSettings(viewModel: viewModel)
                .presentationDetents([.height(300)])
                .background(.black)
        })
    }

    func initializeReader() {
        viewModel.loadReaderHtml()
    }

    func onWebViewDoneLoading(_ isLoading: Bool) {
        if !isLoading && !viewModel.hasLoadedBook {
            viewModel.loadBook(book)
        }
    }

    func relocated(_ relocate: Relocate) {
        let thawedBook = book.thaw()
        try! realm.write {
            if thawedBook?.readingPosition == nil {
                thawedBook?.readingPosition = ReadingPosition()
                thawedBook?.readingPosition?.progress = relocate.fraction
                thawedBook?.readingPosition?.updatedAt = relocate.updatedAt
                thawedBook?.readingPosition?.epubCfi = relocate.cfi
            } else {
                thawedBook?.readingPosition?.progress = relocate.fraction
                thawedBook?.readingPosition?.updatedAt = relocate.updatedAt
                thawedBook?.readingPosition?.epubCfi = relocate.cfi
            }
        }
    }
}

#Preview {
    EBookReader(book: Book.example1)
}

/**

 if false {
     Button {}
         label: {
             Image(systemName: "book.pages")
                 .foregroundStyle(Color.accent)
                 .font(.system(size: 20))
         }
         .padding(12)
         .background(.black)
         .clipShape(.circle)

 } else {
     Button {}
         label: {
             Image(systemName: "scroll")
                 .foregroundStyle(Color.accent)
                 .font(.system(size: 20))
         }
         .padding(12)
         .background(.black)
         .clipShape(.circle)
 }
 */
