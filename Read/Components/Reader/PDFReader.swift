//
//  PDFReader.swift
//  Read
//
//  Created by Mirna Olvera on 2/11/24.
//

import PDFKit
import RealmSwift
import SwiftUI
import UIKit
import UniformTypeIdentifiers

extension UIView {
    class func getAllSubviews<T: UIView>(from parenView: UIView) -> [T] {
        return parenView.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(from: subView) as [T]
            if let view = subView as? T { result.append(view) }
            return result
        }
    }

    func disableMenuInteractions() {
        let views = UIView.getAllSubviews(from: self)
        for view in views {
            for interaction in view.interactions where interaction is UIEditMenuInteraction {
                view.removeInteraction(interaction)
            }
        }
    }
}

class NoContextMenuPDFView: PDFView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override func buildMenu(with builder: UIMenuBuilder) {
        if #available(iOS 16.0, *) {
            builder.remove(menu: .lookup)
            builder.remove(menu: .file)
            builder.remove(menu: .edit)
            builder.remove(menu: .view)
            builder.remove(menu: .window)
            builder.remove(menu: .help)
            builder.remove(menu: .about)
            builder.remove(menu: .preferences)
            builder.remove(menu: .services)
            builder.remove(menu: .hide)
            builder.remove(menu: .quit)
            builder.remove(menu: .newScene)
            builder.remove(menu: .openRecent)
            builder.remove(menu: .close)
            builder.remove(menu: .print)
            builder.remove(menu: .document)
            builder.remove(menu: .undoRedo)
            builder.remove(menu: .standardEdit)
            builder.remove(menu: .find)
            builder.remove(menu: .replace)
            builder.remove(menu: .share)
            builder.remove(menu: .textStyle)
            builder.remove(menu: .spelling)
            builder.remove(menu: .spellingPanel)
            builder.remove(menu: .spellingOptions)
            builder.remove(menu: .substitutions)
            builder.remove(menu: .substitutionsPanel)
            builder.remove(menu: .substitutionOptions)
            builder.remove(menu: .transformations)
            builder.remove(menu: .speech)
            builder.remove(menu: .learn)
            builder.remove(menu: .format)
            builder.remove(menu: .font)
            builder.remove(menu: .textSize)
            builder.remove(menu: .textColor)
            builder.remove(menu: .textStylePasteboard)
            builder.remove(menu: .text)
            builder.remove(menu: .writingDirection)
            builder.remove(menu: .alignment)
            builder.remove(menu: .toolbar)
            builder.remove(menu: .sidebar)
            builder.remove(menu: .fullscreen)
            builder.remove(menu: .minimizeAndZoom)
            builder.remove(menu: .bringAllToFront)
        }

        super.buildMenu(with: builder)
    }
}

struct PDFTocItem {
    var outline: PDFOutline
    var depth: Int
}

class PDFReaderViewModel: ObservableObject {
    var pdfDocument: PDFDocument
    var pdfView: NoContextMenuPDFView
    let url: URL

    @Published var currentPage: PDFPage?
    @Published var showMenuOverlay = false
    @Published var showSettingsSheet = false
    @Published var showContentSheet = false
    @Published var isLoading = true

    @Published var showMenu = false
    @Published var frame: CGSize = .zero
    @Published var position: CGPoint = .zero

    var currentPageLabel: String {
        return currentPage?.label ?? "NO"
    }

    var currentSectionHolder = ""
    var currentLabel: String {
        let first = pdfToc.first { outline in
            outline.outline.destination?.page?.pageRef?.pageNumber == currentPage?.pageRef?.pageNumber
        }

        if first == nil {
            return currentSectionHolder
        }

        currentSectionHolder = first?.outline.label ?? ""
        return first?.outline.label ?? ""
    }

    // page number / total pages
    var currentPageNumberLabel: String {
        guard let currentPage = pdfView.currentPage else {
            return ""
        }
        let index = pdfDocument.index(for: currentPage)
        let pageCount = pdfDocument.pageCount
        return String(format: "%d/%d", index + 1, pageCount)
    }

    var currentTocItemHolder: PDFTocItem?
    var currenTocItem: PDFTocItem? {
        let first = pdfToc.last { outline in
            outline.outline.destination?.page?.pageRef?.pageNumber == currentPage?.pageRef?.pageNumber
        }

        if first == nil {
            return currentTocItemHolder
        }

        currentTocItemHolder = first

        return first
    }

    // Flattend PDF Toc items
    var pdfToc: [PDFTocItem] {
        var toc = [PDFTocItem]()
        if let root = pdfDocument.outlineRoot {
            var stack: [(outline: PDFOutline, depth: Int)] = [(root, -1)]
            while !stack.isEmpty {
                let (current, depth) = stack.removeLast()
                if let label = current.label, !label.isEmpty {
                    toc.append(PDFTocItem(outline: current, depth: depth))
                }
                for i in (0 ..< current.numberOfChildren).reversed() {
                    if let child = current.child(at: i) {
                        stack.append((child, depth + 1))
                    }
                }
            }
        }

        return toc
    }

    init(url: URL) {
        self.url = url
        pdfDocument = PDFDocument(url: url) ?? PDFDocument()
        pdfView = NoContextMenuPDFView()
    }

    func pdfPageChanged() {
        currentPage = pdfView.currentPage

        // Disable popup menu
        pdfView.disableMenuInteractions()
    }

    func highlightSelection() {
        let selections = pdfView.currentSelection?.selectionsByLine()
        // Simple scenario, assuming your pdf is single-page.
        guard let page = selections?.first?.pages.first else {
            showMenu = false
            pdfView.clearSelection()
            return
        }

        selections?.forEach { selection in
            let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
            highlight.endLineStyle = .square
            highlight.color = UIColor.orange.withAlphaComponent(0.5)

            page.addAnnotation(highlight)
        }

        showMenu = false
        pdfView.clearSelection()
    }

    func copySelection() {
        let selections = pdfView.currentSelection?.string
        guard let text = selections else {
            showMenu = false
            return
        }
        UIPasteboard.general.setValue(text, forPasteboardType: UTType.plainText.identifier)
        showMenu = false
        pdfView.clearSelection()
    }
}

class PDFKitViewCoordinator: NSObject, PDFViewDelegate {
    var viewModel: PDFReaderViewModel

    init(viewModel: PDFReaderViewModel) {
        self.viewModel = viewModel
    }

    @objc func handlePageChange(notification: Notification) {
        viewModel.pdfPageChanged()
    }

    @objc func handleAnnotationHit(notification: Notification) {
        if notification.userInfo?["PDFAnnotationHit"] is PDFAnnotation {
            print("annotation Hit")
//            viewModel.pdfAnnotationTapped(annotation: annotation)
        }
    }

    @objc func selectionDidChange(notification: Notification) {
        viewModel.showMenu = false

        guard let selection = viewModel.pdfView.currentSelection,
              let selectionString = selection.string,
              selectionString.count > 0
        else {
            viewModel.showMenu = false
            return
        }

        guard let selectionLastLine = selection.selectionsByLine().last,
              let selectionLastLinePage = selectionLastLine.pages.last
        else {
            viewModel.showMenu = false
            return
        }

        let selectionBound = selectionLastLine.bounds(for: selectionLastLinePage)
        let selectionInView = viewModel.pdfView.convert(selectionBound, from: selectionLastLinePage)

        let buttonSize = CGFloat(viewModel.frame.width)
        _ = CGSize(width: buttonSize, height: viewModel.frame.height)

        let annotationViewPosition = CGPoint(
            x: selectionInView.minX + selectionInView.width / 2.0,
            y: selectionInView.minY + 44
        )

//        if annotationViewPosition.x + annotationViewSize.width + padding > viewModel.pdfView.frame.width {
//            annotationViewPosition.x = viewModel.pdfView.frame.width - buttonSize - padding
//        }
//
//        if annotationViewPosition.y + annotationViewSize.height + padding > viewModel.pdfView.frame.height {
//            annotationViewPosition.y = selectionInView.minY - CGFloat(1) * buttonSize - padding * 2.0
//        }

        viewModel.position = annotationViewPosition
        viewModel.showMenu = true
    }

    @objc func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        if viewModel.pdfView.currentSelection != nil {
            if let currentPage = viewModel.currentPage {
                let bounds = viewModel.pdfView.currentSelection?.bounds(for: currentPage)
                let tapPoint = gestureRecognizer.location(in: nil)
                let convertedPoint = viewModel.pdfView.convert(tapPoint, to: currentPage)

                if let bounds {
                    if bounds.contains(convertedPoint) {
                        return
                    }
                }
            }
            viewModel.pdfView.clearSelection()

            return
        }

        viewModel.showMenuOverlay.toggle()
    }
}

struct PDFKitView: UIViewRepresentable {
    let viewModel: PDFReaderViewModel

    init(viewModel: PDFReaderViewModel) {
        self.viewModel = viewModel
    }

    func makeUIView(context: Context) -> some UIView {
        viewModel.pdfView.autoScales = true
        viewModel.pdfView.displayMode = .singlePage
        viewModel.pdfView.displayDirection = .horizontal
        viewModel.pdfView.usePageViewController(true, withViewOptions: nil)
        viewModel.pdfView.document = viewModel.pdfDocument
        viewModel.pdfView.backgroundColor = .black

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.handlePageChange(notification:)), name: .PDFViewPageChanged, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.handleAnnotationHit(notification:)), name: .PDFViewAnnotationHit, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.selectionDidChange(notification:)), name: .PDFViewSelectionChanged, object: nil)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.tapGesture(_:)))

        viewModel.pdfView.addGestureRecognizer(tap)
        viewModel.pdfView.delegate = context.coordinator

        return viewModel.pdfView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> PDFKitViewCoordinator {
        PDFKitViewCoordinator(viewModel: viewModel)
    }
}

struct ReaderMenu: View {
    @StateObject var viewModel: PDFReaderViewModel

    var height: CGFloat = 44
    var buttonSizeWidth: CGFloat = 44
    var buttonSizeHeight: CGFloat {
        height
    }

    var numberOfButtons: CGFloat = 2

    var body: some View {
        HStack {
            Button {
                viewModel.highlightSelection()
            }
            label: {
                Circle()
                    .fill(.yellow)
                    .frame(width: buttonSizeWidth / 2, height: buttonSizeHeight / 2)
            }
            .frame(width: buttonSizeWidth, height: buttonSizeHeight)
            .background(.black)

            Divider()
                .frame(height: buttonSizeHeight / 2)

            Button {
                viewModel.copySelection()
            }
            label: {
                Image(systemName: "doc.on.doc.fill")
            }
            .frame(width: buttonSizeWidth, height: buttonSizeHeight)
            .background(.black)
        }
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .frame(width: buttonSizeWidth * numberOfButtons, height: buttonSizeHeight)
        .position(viewModel.position)
        .onAppear {
            // TODO: change this
            viewModel.frame.width = buttonSizeWidth * numberOfButtons
            viewModel.frame.height = buttonSizeHeight
        }
    }
}

struct PDFReader: View {
    var realm = try! Realm()

    var book: Book
    var hasBookPath: Bool

    @StateObject var viewModel: PDFReaderViewModel

    init(book: Book) {
        self.book = book

        let url = URL.documentsDirectory.appending(path: book.bookPath ?? "")
        _viewModel = StateObject(wrappedValue: PDFReaderViewModel(url: url))
        hasBookPath = book.bookPath != nil
    }

    var body: some View {
        ZStack {
//            Color(hex: viewModel.theme.bg.rawValue)
//                .ignoresSafeArea()

            if hasBookPath {
                PDFKitView(viewModel: viewModel)
                    .onAppear {
                        viewModel.currentPage = viewModel.pdfView.currentPage

                        if let pos = book.readingPosition?.chapter {
                            if let page = viewModel.pdfDocument.page(at: pos) {
                                viewModel.pdfView.go(to: page)

                                viewModel.currentPage = viewModel.pdfView.currentPage
                            }
                        }
                        viewModel.isLoading = false
                    }

                if viewModel.showMenu {
                    ReaderMenu(viewModel: viewModel)
                }

            } else {
                Text("Something went wrong!")
            }

            if viewModel.showMenuOverlay {
                PDFReaderMenu(book: book, viewModel: viewModel)
                    .ignoresSafeArea()
            }

            if viewModel.isLoading {
                ZStack {
                    Color.black
                    ProgressView()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.showContentSheet, content: {
            PDFReaderContent(viewModel: viewModel)
        })
        .sheet(isPresented: $viewModel.showSettingsSheet, content: {
            Text("SETTINGS")
        })
        .onChange(of: viewModel.currentPage) { _, newValue in
            if let value = newValue {
                relocated(value)
            }
        }
    }

    func relocated(_ currentPage: PDFPage) {
        let totalPages = CGFloat(viewModel.pdfDocument.pageCount)
        let currentPageIndex = CGFloat(viewModel.pdfDocument.index(for: currentPage))
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
}

#Preview {
    PDFReader(book: Book.example1)
}
