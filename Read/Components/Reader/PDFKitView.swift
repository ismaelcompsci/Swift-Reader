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

// class PDFReaderViewModel: ObservableObject {
//    var pdfDocument: PDFDocument
//    var pdfView: NoContextMenuPDFView
//    let url: URL
//
//    @Published var currentPage: PDFPage?
//    @Published var showMenuOverlay = false
//    @Published var showSettingsSheet = false
//    @Published var showContentSheet = false
//    @Published var isLoading = true
//
//    @Published var showMenu = false
//    @Published var frame: CGSize = .zero
//    @Published var position: CGPoint = .zero
//
//    var currentPageLabel: String {
//        return currentPage?.label ?? ""
//    }
//
//    var currentSectionHolder = ""
//    var currentLabel: String {
//        let first = pdfToc.first { outline in
//            outline.outline.destination?.page?.pageRef?.pageNumber == currentPage?.pageRef?.pageNumber
//        }
//
//        if first == nil {
//            return currentSectionHolder
//        }
//
//        currentSectionHolder = first?.outline.label ?? ""
//        return first?.outline.label ?? ""
//    }
//
//    // page number / total pages
//    var currentPageNumberLabel: String {
//        guard let currentPage = pdfView.currentPage else {
//            return ""
//        }
//        let index = pdfDocument.index(for: currentPage)
//        let pageCount = pdfDocument.pageCount
//        return String(format: "%d/%d", index + 1, pageCount)
//    }
//
//    var currentTocItemHolder: PDFTocItem?
//    var currenTocItem: PDFTocItem? {
//        let first = pdfToc.last { outline in
//            outline.outline.destination?.page?.pageRef?.pageNumber == currentPage?.pageRef?.pageNumber
//        }
//
//        if first == nil {
//            return currentTocItemHolder
//        }
//
//        currentTocItemHolder = first
//
//        return first
//    }
//
//    // Flattend PDF Toc items
//    var pdfToc: [PDFTocItem] {
//        var toc = [PDFTocItem]()
//        if let root = pdfDocument.outlineRoot {
//            var stack: [(outline: PDFOutline, depth: Int)] = [(root, -1)]
//            while !stack.isEmpty {
//                let (current, depth) = stack.removeLast()
//                if let label = current.label, !label.isEmpty {
//                    toc.append(PDFTocItem(outline: current, depth: depth))
//                }
//                for i in (0 ..< current.numberOfChildren).reversed() {
//                    if let child = current.child(at: i) {
//                        stack.append((child, depth + 1))
//                    }
//                }
//            }
//        }
//
//        return toc
//    }
//
//    init(url: URL) {
//        self.url = url
//        pdfDocument = PDFDocument(url: url) ?? PDFDocument()
//        pdfView = NoContextMenuPDFView()
//    }
//
//    func pdfPageChanged() {
//        currentPage = pdfView.currentPage
//
//        // Disable popup menu
//        pdfView.disableMenuInteractions()
//    }
//
//    func highlightSelection() {
//        let selections = pdfView.currentSelection?.selectionsByLine()
//        // Simple scenario, assuming your pdf is single-page.
//        guard let page = selections?.first?.pages.first else {
//            showMenu = false
//            pdfView.clearSelection()
//            return
//        }
//
//        selections?.forEach { selection in
//            let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
//            highlight.endLineStyle = .square
//            highlight.color = UIColor.orange.withAlphaComponent(0.5)
//
//            page.addAnnotation(highlight)
//        }
//
//        showMenu = false
//        pdfView.clearSelection()
//    }
//
//    func copySelection() {
//        let selections = pdfView.currentSelection?.string
//        guard let text = selections else {
//            showMenu = false
//            return
//        }
//        UIPasteboard.general.setValue(text, forPasteboardType: UTType.plainText.identifier)
//        showMenu = false
//        pdfView.clearSelection()
//    }
// }

class CustomPage: PDFPage {
    static var bg: CGColor?
    static var fg: CGColor?

    override init() {
        super.init()
    }

    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        super.draw(with: box, to: context)
        if let color = CustomPage.bg, let fgColor = CustomPage.fg {
            context.setFillColor(color)
        }

        // Draw original content

        // get page bounds
        let pageBounds = bounds(for: box)
        // change backgroud color

        // set blend mode
        context.setBlendMode(.multiply)

        var rect = pageBounds
        // you need to switch the width and height for horizontal pages
        // the coordinate system for the context is the lower left corner
        if rotation == 90 || rotation == 270 {
            rect = CGRect(origin: .zero, size: CGSize(width: pageBounds.height, height: pageBounds.width))
        }

        context.fill(rect)
    }
}

class PDFKitViewCoordinator: NSObject, PDFViewDelegate, PDFDocumentDelegate {
    var viewModel: ReaderViewModel

    init(viewModel: ReaderViewModel) {
        self.viewModel = viewModel
    }

    func classForPage() -> AnyClass {
        return CustomPage.self
    }

    @objc func handleVisiblePagesChanged(notification: Notification) {}

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
        viewModel.selectionDidChange()
    }

//        viewModel.showMenu = false
//
//        guard let selection = viewModel.pdfView.currentSelection,
//              let selectionString = selection.string,
//              selectionString.count > 0
//        else {
//            viewModel.showMenu = false
//            return
//        }
//
//        guard let selectionLastLine = selection.selectionsByLine().last,
//              let selectionLastLinePage = selectionLastLine.pages.last
//        else {
//            viewModel.showMenu = false
//            return
//        }
//
//        let selectionBound = selectionLastLine.bounds(for: selectionLastLinePage)
//        let selectionInView = viewModel.pdfView.convert(selectionBound, from: selectionLastLinePage)
//
//        let buttonSize = CGFloat(viewModel.frame.width)
//        _ = CGSize(width: buttonSize, height: viewModel.frame.height)
//
//        let annotationViewPosition = CGPoint(
//            x: selectionInView.minX + selectionInView.width / 2.0,
//            y: selectionInView.minY + 44
//        )

//        viewModel.position = annotationViewPosition
//        viewModel.showMenu = true
//    }

    @objc func tapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let pdfView = viewModel.pdfView else {
            return
        }

        guard let currentPage = viewModel.currentPage else {
            return
        }

//        if viewModel.pdfView.currentSelection != nil {

        let bounds = pdfView.currentSelection?.bounds(for: currentPage)
        let tapPoint = gestureRecognizer.location(in: nil)
        let convertedPoint = pdfView.convert(tapPoint, to: currentPage)

        viewModel.tapped.send(convertedPoint)

//
//                if let bounds {
//                    if bounds.contains(convertedPoint) {
//                        return
//                    }
//                }
//            }
//            viewModel.pdfView.clearSelection()
//
//            return
//        }
//
//        viewModel.showMenuOverlay.toggle()
    }
}

struct PDFKitView: UIViewRepresentable {
    let viewModel: ReaderViewModel

    init(viewModel: ReaderViewModel) {
        self.viewModel = viewModel
    }

    func makeUIView(context: Context) -> NoContextMenuPDFView {
        guard let pdfView = viewModel.pdfView else {
            return NoContextMenuPDFView()
        }

        viewModel.pdfDocument?.delegate = context.coordinator

        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.document = viewModel.pdfDocument

//        let rgba = getRGBFromHex(hex: viewModel.theme.bg.rawValue)
//        pdfView.backgroundColor = UIColor(red: rgba["red"] ?? 0, green: rgba["green"] ?? 0, blue: rgba["blue"] ?? 0, alpha: 1)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.handlePageChange(notification:)), name: .PDFViewPageChanged, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.handleVisiblePagesChanged(notification:)), name: .PDFViewVisiblePagesChanged, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.handleAnnotationHit(notification:)), name: .PDFViewAnnotationHit, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.selectionDidChange(notification:)), name: .PDFViewSelectionChanged, object: nil)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.tapGesture(_:)))

        pdfView.addGestureRecognizer(tap)
        pdfView.delegate = context.coordinator

        return pdfView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> PDFKitViewCoordinator {
        PDFKitViewCoordinator(viewModel: viewModel)
    }
}