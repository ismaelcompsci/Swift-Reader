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
    @State private var showContextMenu: Bool = false
    
    @State private var contextMenuPosition: CGPoint = .zero
    
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
                    .onTapGesture {
                        let script = """
                        function test() {
                        const sel = globalReader?.doc?.getSelection();
                          if (!sel.rangeCount) return false;
                          const range = sel.getRangeAt(0);
                          if (range.collapsed) return false;
                          return true;
                        }
                        
                        !!test();
                        """
                        viewModel.webView?.evaluateJavaScript(script, completionHandler: { success, error in
                            if let success {
                                if success as! Bool == true {
                                    showContextMenu = false
                                }
                            }
                            
                            if let error {
                                print(error)
                            }
                        })
                    }
                   
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
                ReaderOverlay(book: book, viewModel: viewModel)
            }
            
            if showContextMenu && contextMenuPosition != .zero {
                ReaderContextMenu(viewModel: viewModel, showContextMenu: $showContextMenu, position: contextMenuPosition)
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
        .onReceive(viewModel.selectionChanged, perform: selectionChanged)
    }
    
    private func selectionChanged(selectionSelected: Selection?) {
        if viewModel.isPDF && selectionSelected == nil {
            showContextMenu = false
            
            guard let selection = viewModel.pdfView?.currentSelection,
                  let selectionString = selection.string,
                  selectionString.count > 0
            else {
                showContextMenu = false
                return
            }
            
            guard let selectionLastLine = selection.selectionsByLine().last,
                  let selectionLastLinePage = selectionLastLine.pages.last
            else {
                showContextMenu = false
                return
            }
            
            let selectionBound = selectionLastLine.bounds(for: selectionLastLinePage)
            let selectionInView = viewModel.pdfView?.convert(selectionBound, from: selectionLastLinePage)
            
            guard let selectionInView else {
                return
            }
            
            let annotationViewPosition = CGPoint(
                x: selectionInView.minX + selectionInView.width / 2.0,
                y: selectionInView.minY + 52
            )

            contextMenuPosition = annotationViewPosition
            showContextMenu = true
        } else {
            showContextMenu = false
            
            guard let selectedText = selectionSelected?.string, selectedText.count > 0 else {
                showContextMenu = false
                return
            }
            
            guard let bounds = selectionSelected?.bounds else {
                showContextMenu = false
                return
            }
            
            let annotationViewPosition = CGPoint(
                x: bounds.origin.x,
                y: bounds.origin.y
            )
            
            contextMenuPosition = annotationViewPosition
            showContextMenu = true
        }
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
        if viewModel.isPDF {
            guard let pdfView = viewModel.pdfView else {
                return
            }
            
            guard let currentPage = viewModel.currentPage else {
                return
            }
            
            if pdfView.currentSelection != nil {
                let bounds = pdfView.currentSelection?.bounds(for: currentPage)
                
                if let bounds {
                    if bounds.contains(point) {
                        return
                    }
                }
                
                pdfView.clearSelection()
                
                return
            }
            
            withAnimation {
                showOverlay.toggle()
            }
        } else {
            showContextMenu = false

            withAnimation {
                showOverlay.toggle()
            }
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
