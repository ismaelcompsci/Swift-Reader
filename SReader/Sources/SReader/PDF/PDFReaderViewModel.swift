//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/20/24.
//

import Combine
import Foundation
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public protocol Reader {
    var file: URL { get }
    var state: ReaderState { get }

    var currentLocation: SRLocator? { get }
    var initialLocation: SRLocator? { get }
    var currentSelection: SRSelection? { get }
    var currentTocLink: SRLink? { get }
    var toc: [SRLink] { get }
    var flattenedToc: [(level: Int, link: SRLink)] { get }
    var theme: BookTheme { get set }

    var onHighlighted: PassthroughSubject<SRHighlight, Never> { get }
    var onRemovedHighlight: PassthroughSubject<SRHighlight, Never> { get }
    var onRelocated: PassthroughSubject<SRLocator, Never> { get }
    var onTap: PassthroughSubject<CGPoint, Never> { get }

    init(file: URL, initialLocation: SRLocator?)

    func start(highlights: [SRHighlight])
    func goTo(for link: SRLink)
    func goTo(for locater: SRLocator)

    func setTheme()
    func highlightSelection()

    func goForward()
    func goBackward()

    func removeHighlight(_ highlight: SRHighlight)
    func editHighlight(_ highlight: SRHighlight, style: HighlightColor)
    func injectHighlight(_ highlight: SRHighlight)
}

public extension PDFAnnotationKey {
    static let highlightId: PDFAnnotationKey = .init(rawValue: "/HID")
}

@MainActor
@Observable public class PDFReaderViewModel: Reader {
    public var file: URL
    public var pdfDocument: PDFDocument
    public var pdfView: NoContextMenuPDFView

    public var theme = BookTheme()
    public var state: ReaderState = .loading
    public var currentLocation: SRLocator?
    public var initialLocation: SRLocator?

    public var editingActions: EditingActionsController!
    public var highlightActions: EditingActionsController!

    @ObservationIgnored
    public var currentSelection: SRSelection?
    public var currentTocLink: SRLink?

    public var toc: [SRLink]
    public var flattenedToc: [(level: Int, link: SRLink)] {
        func flatten(_ links: [SRLink], level: Int = 0) -> [(level: Int, link: SRLink)] {
            links.flatMap { [(level, $0)] + flatten($0.children, level: level + 1) }
        }

        return flatten(toc)
    }

    public var onTap = PassthroughSubject<CGPoint, Never>()
    public var onHighlighted = PassthroughSubject<SRHighlight, Never>()
    public var onRemovedHighlight = PassthroughSubject<SRHighlight, Never>()
    public var onRelocated = PassthroughSubject<SRLocator, Never>()

    private var highlights = [String: SRHighlight]()

    public required init(
        file: URL,
        initialLocation: SRLocator? = nil
    ) {
        self.file = file
        self.initialLocation = initialLocation
        self.pdfDocument = PDFDocument(url: file) ?? PDFDocument()
        self.pdfView = NoContextMenuPDFView()
        self.toc = []

        setupActions()
    }

    public func start(highlights: [SRHighlight] = []) {
        if state == .ready {
            state = .loading
        }

        pdfView.isHidden = true
        setTheme()

        toc = generateLinks()

        for highlight in highlights {
            injectHighlight(highlight)
        }

        selectedHighlight = nil

        if let initialLocation = initialLocation {
            goTo(for: initialLocation)
        }

        // generous delay to stop  color flashes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.pdfView.isHidden = false
            self.state = .ready
        }
    }

    func pdfPageChanged() {
        var currentPageIndex: Int?
        var currentTocItemForPage: SRLink?

        if let currentPage = pdfView.currentPage {
            currentPageIndex = pdfDocument.index(for: currentPage) + 1

            if let currentPageIndex = currentPageIndex {
                currentTocItemForPage = find(index: currentPageIndex)
            }
        }

        let totalProgression = currentPageIndex != nil ?
            Double(currentPageIndex!) / Double(pdfDocument.pageCount
            ) : nil

        let locater = SRLocator(
            type: .pdf,
            title: currentTocItemForPage?.title ?? "",
            locations: .init(
                fragments: currentPageIndex != nil ? ["page=\(currentPageIndex!)"] : [],
                progression: totalProgression,
                totalProgression: totalProgression,
                position: currentPageIndex
            )
        )

        onRelocated.send(locater)
        currentLocation = locater
        currentTocLink = currentTocItemForPage
    }

    public func setTheme() {
        let rgba = getRGBFromHex(hex: theme.bg.rawValue)

        pdfView.backgroundColor = UIColor(
            red: rgba["red"] ?? 0,
            green: rgba["green"] ?? 0,
            blue: rgba["blue"] ?? 0,
            alpha: 1
        )
        PDFPageCustomBackground.bg = CGColor(
            red: rgba["red"] ?? 0,
            green: rgba["green"] ?? 0,
            blue: rgba["blue"] ?? 0,
            alpha: 1
        )

        pdfView.goToNextPage(nil)
        pdfView.goToPreviousPage(nil)

        theme.save()
    }

    // https://github.com/readium/swift-toolkit/blob/a3635b5f1eb28a52e73aeb14240479f5979887bc/Sources/Shared/Toolkit/PDF/CGPDF.swift#L123
    private func generateLinks() -> [SRLink] {
        guard let outline = pdfDocument.documentRef?.outline as? [String: Any] else {
            return []
        }

        func node(from dictionary: [String: Any]) -> PDFOutlineNode? {
            guard let pageNumber = dictionary[kCGPDFOutlineDestination as String] as? Int else {
                return nil
            }

            return PDFOutlineNode(
                title: dictionary[kCGPDFOutlineTitle as String] as? String,
                pageNumber: pageNumber,
                children: nodes(in: dictionary[kCGPDFOutlineChildren as String] as? [[String: Any]])
            )
        }

        func nodes(in children: [[String: Any]]?) -> [PDFOutlineNode] {
            guard let children = children else {
                return []
            }

            return children.compactMap { node(from: $0) }
        }

        let outlineNodes = nodes(in: outline[kCGPDFOutlineChildren as String] as? [[String: Any]])

        return outlineNodes.map { $0.link() }
    }

    func find(index pageNumber: Int) -> SRLink? {
        toc.first(where: { $0.href.contains("page=\(pageNumber)") })
    }

    private func pageNumber(for locator: SRLocator) -> Int? {
        for fragment in locator.locations.fragments {
            let optionalPageParam = fragment
                .components(separatedBy: "#")
                .map { $0.components(separatedBy: "=") }
                .first { $0.first == "page" && $0.count == 2 }

            guard let pageParam = optionalPageParam, let pageNumber = Int(pageParam[1]) else {
                return nil
            }

            return pageNumber
        }

        guard let position = locator.locations.position else {
            return nil
        }

        return position
    }

    private var selectedHighlight: SRHighlight?
}

extension PDFReaderViewModel {
    public func highlightSelection() {
        guard let currentSelection = currentSelection else {
            return
        }

        if selectedHighlight != nil {
            return
        }

        let highlight = SRHighlight(
            id: UUID().uuidString,
            locator: currentSelection.locator,
            color: .yellow
        )

        injectHighlight(highlight)
        onHighlighted.send(highlight)
    }

    func getRectFromFragment(_ fragment: String) -> CGRect? {
        let lineRect = fragment.split(separator: "=").last.map(String.init)

        guard var lineCGRect = lineRect?.split(separator: ",").compactMap(Double.init) else {
            return nil
        }

        guard let height = lineCGRect.popLast(),
              let width = lineCGRect.popLast(),
              let y = lineCGRect.popLast(),
              let x = lineCGRect.popLast()
        else {
            return nil
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }

    func selectionDidChange() {
        selectedHighlight = nil

        guard
            let selection = pdfView.currentSelection,
            let page = selection.pages.first,
            let locator = currentLocation,
            let text = pdfView.currentSelection?.string
        else {
            editingActions.selection = nil
            return
        }

        var bounds = [CGRect]()
        selection.selectionsByLine().forEach { line in

            bounds.append(line.bounds(for: page))
        }

        var boundsFragments: [String] = bounds.map {
            "line=\($0.origin.x),\($0.origin.y),\($0.width),\($0.height)"
        }

        if let pageNumber = locator.locations.fragments.first {
            boundsFragments.append(pageNumber)
        } else if let pageNumber = page.pageRef?.pageNumber {
            boundsFragments.append("page=\(pageNumber)")
        }

        var selectionLocater = locator
        selectionLocater.locations.fragments = boundsFragments
        selectionLocater.text = text

        let srselection = SRSelection(
            locator: selectionLocater,
            frame: pdfView.convert(selection.bounds(for: page), from: page)
                // Makes it slightly bigger to have more room when displaying a popover.
                .insetBy(dx: -8, dy: -8)
        )

        currentSelection = srselection
        editingActions.toggleRemoveHighlight(true)
        editingActions.selection = srselection
    }

    public func highlightHit(_ id: String) {
        if let highlight = highlights[id] {
            selectedHighlight = highlight
            editingActions.toggleRemoveHighlight(false)

            if let firstFrag = highlight.locator.locations.fragments.first,
               firstFrag.starts(with: "line"),
               let bounds = getRectFromFragment(firstFrag),
               let page = pdfView.currentPage
            {
                let selection = SRSelection(
                    locator: highlight.locator,
                    frame: pdfView.convert(bounds, from: page)
                        .insetBy(dx: -8, dy: -8)
                )

                editingActions.selection = selection
                currentSelection = selection
            }
        }
    }

    public func injectHighlight(_ highlight: SRHighlight) {
        guard let pageNumber = highlight.locator.locations.position,
              let highlightPage = pdfDocument.page(at: pageNumber - 1) else { return }

        highlight.locator.locations.fragments.forEach { fragment in
            guard fragment.starts(with: "line") else { return }

            if let bounds = getRectFromFragment(fragment) {
                let annotation = PDFAnnotation(
                    bounds: bounds,
                    forType: highlight.color.pdfAnnotationSubtype.0,
                    withProperties: [PDFAnnotationKey.highlightId: highlight.id]
                )

                annotation.color = highlight.color.pdfAnnotationSubtype.1
                highlightPage.addAnnotation(annotation)
            }
        }

        selectedHighlight = highlight
        highlights[highlight.id] = highlight
        pdfView.clearSelection()
    }

    public func editHighlight(_ highlight: SRHighlight, style: HighlightColor) {
        var modifiedHighlight = highlight

        removeHighlight(highlight)
        modifiedHighlight.color = style

        injectHighlight(modifiedHighlight)
        highlights[modifiedHighlight.id] = modifiedHighlight
        onHighlighted.send(modifiedHighlight)
    }

    public func removeHighlight(_ highlight: SRHighlight) {
        highlights.removeValue(forKey: highlight.id)

        if let page = highlight.locator.locations.position {
            let annotationPage = pdfDocument.page(at: page - 1)

            annotationPage?.annotations.forEach { ann in
                if let pageAnnotaionId = ann.annotationKeyValues[PDFAnnotationKey.highlightId] as? String,
                   pageAnnotaionId == highlight.id
                {
                    annotationPage?.removeAnnotation(ann)
                }
            }
        }

        onRemovedHighlight.send(highlight)
    }

    func setupActions() {
        var editingActions: [EditingAction] = ReaderEditingActions.allCases.compactMap {
            if $0 == .removeHighlight {
                return EditingAction(
                    title: ReaderEditingActions.removeHighlight.rawValue,
                    identifier: .init(ReaderEditingActions.removeHighlight.rawValue),
                    attributes: .hidden,
                    handler: editingActionHandler
                )
            }

            return EditingAction(
                title: $0.rawValue,
                identifier: .init($0.rawValue),
                handler: editingActionHandler
            )
        }

        editingActions.append(contentsOf: EditingAction.defaultActions)

        let highlightActions = HighlightColor.allCases.map {
            if $0 == .underline {
                let config = UIImage.SymbolConfiguration(paletteColors: [.systemRed, .label])
                let underlineImage = UIImage(systemName: "underline", withConfiguration: config)

                return EditingAction(
                    title: "",
                    image: underlineImage,
                    identifier: .init(String($0.rawValue)),
                    handler: highlightActionHandler
                )
            }

            let config = UIImage.SymbolConfiguration(paletteColors: [$0.color])
            let circle = UIImage(systemName: "circle.fill", withConfiguration: config)

            return EditingAction(
                title: "",
                image: circle,
                identifier: .init(String($0.rawValue)),
                handler: highlightActionHandler
            )
        }

        self.editingActions = EditingActionsController(actions: editingActions)
        self.highlightActions = EditingActionsController(actions: highlightActions, addSuggestesActions: false)
    }

    func editingActionHandler(_ action: UIAction) {
        let title = action.title

        if let actionType = ReaderEditingActions(rawValue: title) {
            switch actionType {
            case .highlight:
                highlightActions.selection = currentSelection
                highlightSelection()
            case .removeHighlight:
                if let selectedHighlight = selectedHighlight {
                    removeHighlight(selectedHighlight)
                }
            }
        }
    }

    func highlightActionHandler(_ action: UIAction) {
        if let intType = Int(action.identifier.rawValue),
           let color = HighlightColor(rawValue: intType),
           let selectedHighlight = selectedHighlight
        {
            editHighlight(selectedHighlight, style: color)
        }

        selectedHighlight = nil
    }
}

public extension PDFReaderViewModel {
    func goForward() {
        pdfView.goToNextPage(nil)
    }

    func goBackward() {
        pdfView.goToPreviousPage(nil)
    }

    // #page=\(pageNumber)
    func goTo(for link: SRLink) {
        let fragments = link.href.split(separator: "#", maxSplits: 1).map(String.init)
        let fragment = fragments.indices.contains(0) ? fragments[0] : nil
        let pageNumberString = fragment?.split(separator: "=").last.map(String.init)

        guard let pageNumberString = pageNumberString, let pageNumber = Int(pageNumberString) else {
            return
        }

        guard let page = pdfDocument.page(at: pageNumber - 1) else {
            return
        }

        pdfView.go(to: page)
    }

    func goTo(for locater: SRLocator) {
        guard let pageNumber = pageNumber(for: locater),
              let page = pdfDocument.page(at: pageNumber - 1)
        else {
            return
        }

        pdfView.go(to: page)
    }
}

public struct PDFOutlineNode {
    public let title: String?
    public let pageNumber: Int
    public let children: [PDFOutlineNode]

    public func link() -> SRLink {
        SRLink(
            href: "#page=\(pageNumber)",
            title: title,
            type: .pdf,
            children: children.map { $0.link() }
        )
    }
}
