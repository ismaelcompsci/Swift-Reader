//
//  PDFReader+View.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import PDFKit
import SwiftUI

/**
 https://github.com/drearycold/YetAnotherEBookReader/blob/6b1c67cee92917d53aea418956e5fbbd46342420/YetAnotherEBookReader/Views/PDFView/YabrPDFView.swift#L160
 */

class NoContextMenuPDFView: PDFView {
    var singleTapGestureRecognizer: UITapGestureRecognizer?
    var doubleTapGestureRecognizer: UITapGestureRecognizer?

    var viewModel: PDFViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupGestureRecognizers() {
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedGestureHandler(sender:)))

        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.delegate = self
        singleTapGestureRecognizer.delaysTouchesEnded = true
        addGestureRecognizer(singleTapGestureRecognizer)
        self.singleTapGestureRecognizer = singleTapGestureRecognizer
    }

    @objc func tappedGestureHandler(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let tapPoint = sender.location(in: self)

            let aoi = areaOfInterest(for: tapPoint)

            guard aoi.contains(.annotationArea) else {
                viewModel?.onTapped.send(tapPoint)
                return
            }

            let tappedHighlightsValues = viewModel?.highlights.reduce(into: [HighlightValue]()) { partialResult, entry in
                entry.value.forEach { highlightValue in
                    if highlightValue.annotations.filter({
                        guard let page = $0.page else { return false }

                        let pageLocation = self.convert(tapPoint, to: page)

                        return $0.bounds.contains(pageLocation)
                    }).isEmpty == false {
                        partialResult.append(highlightValue)
                    }
                }
            }

            if let tappedHighlight = tappedHighlightsValues?.first,
               let tappedAnnotation = tappedHighlight.annotations.first,
               let tappedUUIDString = tappedAnnotation.value(forAnnotationKey: .highlightId) as? String,
               let tappedUUID = UUID(uuidString: tappedUUIDString),
               let tappedHighlightValue = viewModel?.highlights[tappedUUID],
               let tappedAnnotationFirst = tappedHighlightValue.first?.annotations.first,
               let page = tappedAnnotationFirst.page
            {
                viewModel?.tappedHighlight = tappedUUID

                let bounds = convert(tappedAnnotationFirst.bounds, from: page)
                viewModel?.onTappedHighlight.send(TappedPDFHighlight(bounds: bounds, UUID: tappedUUID))
            }
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == singleTapGestureRecognizer || gestureRecognizer == doubleTapGestureRecognizer {
            if otherGestureRecognizer is UILongPressGestureRecognizer { return false }
            if otherGestureRecognizer is UIPanGestureRecognizer { return false }

            if gestureRecognizer == doubleTapGestureRecognizer && otherGestureRecognizer == singleTapGestureRecognizer { return false }
            if gestureRecognizer == singleTapGestureRecognizer && otherGestureRecognizer == doubleTapGestureRecognizer { return false }
            return true
        }

        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
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

class PDFPageCustomBackground: PDFPage {
    static var bg: CGColor?
    static let colorSpace = CGColorSpaceCreateDeviceRGB()

    override init() {
        super.init()
    }

    // https://github.com/drearycold/YetAnotherEBookReader/blob/6b1c67cee92917d53aea418956e5fbbd46342420/YetAnotherEBookReader/Views/PDFView/PDFPageWithBackground.swift#L11
    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        super.draw(with: box, to: context)

        guard let fillColor = PDFPageCustomBackground.bg,
              let fillColorDeviceRGB = fillColor.converted(to: PDFPageCustomBackground.colorSpace, intent: .defaultIntent, options: nil)
        else {
            print("[PDFPageCustomBackground] draw:  NO FILL COLOR OR DEVICE RGB")
            return
        }

        let grayComponents = fillColor.converted(to: CGColorSpace(name: CGColorSpace.linearGray)!, intent: .defaultIntent, options: nil)?.components ?? []

        let rect = bounds(for: box)

        if grayComponents.count > 1, grayComponents[0] < 0.3 {
            UIGraphicsPushContext(context)
            context.saveGState()

            context.setBlendMode(.exclusion)
            context.setFillColor(gray: 1.0 - grayComponents[0], alpha: 1.0)
            context.fill(rect.offsetBy(dx: -rect.minX, dy: -rect.minY))

            context.setBlendMode(.darken)
            context.setFillColor(gray: 0.7, alpha: 1.0)
            context.fill(rect.offsetBy(dx: -rect.minX, dy: -rect.minY))

            context.restoreGState()
            UIGraphicsPopContext()
        } else {
            UIGraphicsPushContext(context)
            context.saveGState()
            context.setBlendMode(.darken)
            context.setFillColor(fillColorDeviceRGB)
            context.fill(rect.offsetBy(dx: -rect.minX, dy: -rect.minY))
            context.restoreGState()
            UIGraphicsPopContext()
        }
    }
}

class PDFKitViewCoordinator: NSObject, PDFViewDelegate, PDFDocumentDelegate {
    var viewModel: PDFViewModel

    init(viewModel: PDFViewModel) {
        self.viewModel = viewModel
    }

    func classForPage() -> AnyClass {
        return PDFPageCustomBackground.self
    }

    @objc func handleVisiblePagesChanged(notification: Notification) {}

    @objc func handlePageChange(notification: Notification) {
        viewModel.pdfPageChanged()
    }

    @objc func selectionDidChange(notification: Notification) {
        if viewModel.pdfView.currentSelection != nil {
            viewModel.onSelectionChanged.send()
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let viewModel: PDFViewModel

    init(viewModel: PDFViewModel) {
        self.viewModel = viewModel
    }

    func makeUIView(context: Context) -> NoContextMenuPDFView {
        let pdfView = viewModel.pdfView

        viewModel.pdfDocument.delegate = context.coordinator
        pdfView.viewModel = viewModel

        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.document = viewModel.pdfDocument

        pdfView.setupGestureRecognizers()

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.handlePageChange(notification:)), name: .PDFViewPageChanged, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.handleVisiblePagesChanged(notification:)), name: .PDFViewVisiblePagesChanged, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(context.coordinator.selectionDidChange(notification:)), name: .PDFViewSelectionChanged, object: nil)

        pdfView.delegate = context.coordinator

        return pdfView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> PDFKitViewCoordinator {
        PDFKitViewCoordinator(viewModel: viewModel)
    }
}
