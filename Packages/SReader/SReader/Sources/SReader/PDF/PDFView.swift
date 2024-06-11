//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/20/24.
//

import PDFKit
import SwiftUI

/**
 https://github.com/drearycold/YetAnotherEBookReader/blob/6b1c67cee92917d53aea418956e5fbbd46342420/YetAnotherEBookReader/Views/PDFView/YabrPDFView.swift#L160
 */
public class NoContextMenuPDFView: PDFView {
    public var viewModel: PDFReaderViewModel?

    public init() {
        super.init(frame: .zero)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let viewModel = viewModel else { return false }
        return super.canPerformAction(action, withSender: sender) && viewModel.editingActions.canPerformAction(action)
    }

    override public func buildMenu(with builder: any UIMenuBuilder) {
        viewModel?.editingActions.buildMenu(with: builder)
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

public class PDFKitViewCoordinator: NSObject, PDFViewDelegate, PDFDocumentDelegate {
    var viewModel: PDFReaderViewModel

    init(viewModel: PDFReaderViewModel) {
        self.viewModel = viewModel
    }

    public func classForPage() -> AnyClass {
        return PDFPageCustomBackground.self
    }

    @objc func handleAnnotationHit(notification: Notification) {
        if let highlight = notification.userInfo?["PDFAnnotationHit"] as? PDFAnnotation {
            if let id = highlight.annotationKeyValues[PDFAnnotationKey.highlightId] as? String {
                viewModel.highlightHit(id)
            }
        }
    }

    @objc func handleVisiblePagesChanged(notification: Notification) {}

    @objc func handlePageChange(notification: Notification) {
        viewModel.pdfPageChanged()
    }

    @objc func selectionDidChange(notification: Notification) {
        if viewModel.pdfView.currentSelection != nil {
            viewModel.selectionDidChange()
        }
    }
}

public struct PDFKitView: UIViewRepresentable {
    let viewModel: PDFReaderViewModel

    public init(viewModel: PDFReaderViewModel) {
        self.viewModel = viewModel
    }

    public func makeUIView(context: Context) -> NoContextMenuPDFView {
        let pdfView = viewModel.pdfView

        viewModel.pdfDocument.delegate = context.coordinator
        pdfView.viewModel = viewModel

        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.document = viewModel.pdfDocument

        let _ = pdfView.interactions.map { pdfView.removeInteraction($0) }

        pdfView.addInteraction(viewModel.editingActions.editMenuInteraction)
        pdfView.addInteraction(viewModel.highlightActions.editMenuInteraction)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handlePageChange(notification:)),
            name: .PDFViewPageChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handleAnnotationHit(notification:)),
            name: .PDFViewAnnotationHit,
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.handleVisiblePagesChanged(notification:)),
            name: .PDFViewVisiblePagesChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.selectionDidChange(notification:)),
            name: .PDFViewSelectionChanged,
            object: nil
        )

        pdfView.delegate = context.coordinator

        return pdfView
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {}

    public func makeCoordinator() -> PDFKitViewCoordinator {
        PDFKitViewCoordinator(viewModel: viewModel)
    }
}
