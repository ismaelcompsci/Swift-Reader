//
//  Reader.swift
//  Read
//
//  Created by Mirna Olvera on 2/15/24.
//

import PDFKit
import RealmSwift
import SwiftUI

struct Reader: View {
    var realm = try! Realm()

    var book: Book
    var url: URL

    @StateObject var viewModel: ReaderViewModel
    @State private var showOverlay: Bool = false

    init(book: Book) {
        self.book = book
        let bookPathURL = URL.documentsDirectory.appending(path: book.bookPath ?? "")
        url = bookPathURL
        let isPDF = book.bookPath?.hasSuffix(".pdf") ?? false
        _viewModel = StateObject(wrappedValue: ReaderViewModel(url: bookPathURL, isPDF: isPDF, cfi: book.readingPosition?.epubCfi, pdfPageNumber: book.readingPosition?.chapter))
    }

    var body: some View {
        ZStack {
            Color(hex: viewModel.theme.bg.rawValue)
                .ignoresSafeArea()

            // MARK: Reader WebView

            if !viewModel.isPDF {
                ReaderWebView(viewModel: viewModel)
            } else {
                PDFKitView(viewModel: viewModel)
                    .onAppear {
                        viewModel.currentPage = viewModel.pdfView?.currentPage

                        if let pageIndex = book.readingPosition?.chapter {
                            viewModel.goTo(pageIndex: pageIndex)
                        }
                    }
            }

            // MARK: Reader Menu

            if showOverlay {
                ReaderMenu(book: book, viewModel: viewModel)
            }

            // MARK: Loader

            if viewModel.isLoading {
                ZStack {
                    Color.black
                    ProgressView()
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.showContentSheet, content: {
            ReaderContent(viewModel: viewModel)
        })
        .sheet(isPresented: $viewModel.showSettingsSheet, content: {
            ReaderSettings(viewModel: viewModel)
                .presentationDetents([.height(300)])
                .background(.black)
        })
        .onReceive(viewModel.tapped, perform: handleTap)
        .onReceive(viewModel.bookRelocated, perform: relocated)
        .onReceive(viewModel.pdfRelocated, perform: relocatedPDF)
    }

    private func relocated(relocate: Relocate) {
        let thawedBook = book.thaw()
        try! realm.write {
            if thawedBook?.readingPosition == nil {
                thawedBook?.readingPosition = ReadingPosition()
                thawedBook?.readingPosition?.progress = relocate.fraction
                thawedBook?.readingPosition?.updatedAt = relocate.updatedAt ?? .now
                thawedBook?.readingPosition?.epubCfi = relocate.cfi
            } else {
                thawedBook?.readingPosition?.progress = relocate.fraction
                thawedBook?.readingPosition?.updatedAt = relocate.updatedAt ?? .now
                thawedBook?.readingPosition?.epubCfi = relocate.cfi
            }
        }
    }

    func relocatedPDF(currentPage: PDFPage) {
        guard let pdfDocument = viewModel.pdfDocument else {
            return
        }

        let totalPages = CGFloat(pdfDocument.pageCount)
        let currentPageIndex = CGFloat(pdfDocument.index(for: currentPage))
        let updatedAt: Date = .now

        let thawedBook = book.thaw()
        try! realm.write {
            if thawedBook?.readingPosition == nil {
                thawedBook?.readingPosition = ReadingPosition()
                thawedBook?.readingPosition?.progress = currentPageIndex / totalPages
                thawedBook?.readingPosition?.updatedAt = updatedAt
                thawedBook?.readingPosition?.chapter = Int(currentPageIndex)

            } else {
                thawedBook?.readingPosition?.progress = currentPageIndex / totalPages
                thawedBook?.readingPosition?.updatedAt = updatedAt
                thawedBook?.readingPosition?.chapter = Int(currentPageIndex)
            }
        }
    }

    private func handleTap(point: CGPoint) {
        withAnimation {
            showOverlay.toggle()
        }
    }
}

#Preview {
    Reader(book: .example1)
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
