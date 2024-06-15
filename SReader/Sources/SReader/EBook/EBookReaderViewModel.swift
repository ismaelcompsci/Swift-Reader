//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/17/24.
//

import Combine
import GCDWebServers
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct InjectedHighlight: Codable {
    var index: Int
    var value: String
    var color: String
}

@MainActor
@Observable public class EBookReaderViewModel: Reader {
    let webView: NoContextMenuWebView
    let webServer: WebServer
    public let file: URL

    public var state: ReaderState = .loading
    public var theme = BookTheme()
    public var currentLocation: SRLocator?
    public var initialLocation: SRLocator?
    public var currentTocLink: SRLink?

    @ObservationIgnored
    public var currentSelection: SRSelection?
    public var toc: [SRLink]

    public var flattenedToc: [(level: Int, link: SRLink)] {
        func flatten(_ links: [SRLink], level: Int = 0) -> [(level: Int, link: SRLink)] {
            links.flatMap { [(level, $0)] + flatten($0.children, level: level + 1) }
        }

        return flatten(toc)
    }

    public var editingActions: EditingActionsController!
    public var highlightActions: EditingActionsController!

    var finishedLoadingJavascript: Bool = false { didSet { readyToRender() }}
    private var constructedJavascriptReader: Bool = false { didSet { readyToRender() }}

    public var onRelocated = PassthroughSubject<SRLocator, Never>()
    public var onTap = PassthroughSubject<CGPoint, Never>()
    public var onHighlighted = PassthroughSubject<SRHighlight, Never>()
    public var onRemovedHighlight = PassthroughSubject<SRHighlight, Never>()

    private var highlights = [String: SRHighlight]()
    private var highlightsByCFI = [String: SRHighlight]()
    private var initialHighlights = [SRHighlight]()

    public required init(file: URL, initialLocation: SRLocator? = nil) {
        self.file = file
        self.webView = NoContextMenuWebView()
        self.initialLocation = initialLocation
        self.webServer = WebServer()
        self.toc = []

        webServer.setUpWebServer()

        setupActions()
    }

    public func start(highlights: [SRHighlight] = []) {
        if webView.url != nil {
            webView.isHidden = false
            return
        }

        webView.isHidden = true
        webServer.file = file
        let baseURL = webServer.fileServer.base
        webView.load(.init(url: URL(string: baseURL)!))
        initialHighlights = highlights
    }

    private func readyToRender() {
        if finishedLoadingJavascript == true, constructedJavascriptReader == true, state != .ready {
            Task {
                await renderEBook(initialLocation: initialLocation)
                setTheme()
                self.toc = await generateLinks()

                self.injectInitialHighlights()
                selectedHighlight = nil

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.webView.isHidden = false
                    self.state = .ready
                }
            }
        }
    }

    private func injectInitialHighlights() {
        do {
            let injectHighlights: [InjectedHighlight] = initialHighlights.compactMap {
                guard let value = getCfi(for: $0.locator), let index = $0.locator.locations.position else { return nil }

                highlightsByCFI[value] = $0
                highlights[$0.id] = $0

                return InjectedHighlight(
                    index: index,
                    value: value,
                    color: $0.color.description
                )
            }

            let jsonAnnotations = try JSONEncoder().encode(injectHighlights)
            let stringJSONAnnotations = String(data: jsonAnnotations, encoding: .utf8) ?? "[]"

            let script = """
            globalReader?.setAnnotations(\(stringJSONAnnotations))
            """

            DispatchQueue.main.async {
                self.webView.evaluateJavaScript(
                    script,
                    in: nil,
                    in: .page
                ) { result in
                    switch result {
                    case .success(let success):
                        print("SUCCESS: \(success)")
                    case .failure(let error):
                        print("ERROR: \(error)")
                    }
                }
            }

        } catch {
            print("ERROR: \(error)")
        }
    }

    public func renderEBook(initialLocation: SRLocator?) async {
        var args: String

        let ext = file.pathExtension

        if let initialLocation = initialLocation, let cfi = getCfi(for: initialLocation) {
            args = "`\(webServer.fileServer.base)/api/book`, `\(cfi)`, `.\(ext)`"
        } else if let progression = initialLocation?.locations.progression {
            args = "`\(webServer.fileServer.base)/api/book`, \(progression), `.\(ext)`"
        } else {
            args = "`\(webServer.fileServer.base)/api/book`, undefined, `.\(ext)`"
        }

        let script = """
        var initPromise =  globalReader?.initBook(\(args))
        await initPromise
        return initPromise
        """

        do {
            _ = try await webView.callAsyncJavaScript(script, contentWorld: .page)

        } catch {
            state = .error(error.localizedDescription)
            print("Failed to initate book: \(error.localizedDescription)")
        }
    }

    func handleMessage(from messageCase: BookWebViewMessageHandlers, with message: Data) {
        switch messageCase {
        case .initiatedSwiftReader:
            constructedJavascriptReader = true
        case .tapHandler:
            // convert to correct space coordinates
            if let pointData = try? JSONDecoder().decode([String: Double].self, from: message),
               let x = pointData["x"],
               let y = pointData["y"]
            {
                onTap.send(.init(x: x, y: y))
            }
        case .selectedText:
            selectedHighlight = nil
            if let selectedText = try? JSONDecoder().decode(FoliateSelection.self, from: message) {
                guard var selectionLocater = currentLocation else {
                    return
                }

                editingActions.toggleRemoveHighlight(true)

                selectionLocater.locations.position = selectedText.index
                selectionLocater.locations.fragments = ["cfi=\(selectedText.value)"]
                selectionLocater.text = selectedText.text

                let selection = SRSelection(
                    locator: selectionLocater,
                    frame: .init(
                        x: selectedText.x,
                        y: selectedText.y,
                        width: selectedText.width,
                        height: selectedText.height
                    )
                )

                currentSelection = selection
                editingActions.selection = selection
            }

        case .relocate:
            if let relocateDetails = try? JSONDecoder().decode(Relocate.self, from: message) {
                currentTocLink = SRLink(
                    href: "#cfi=\(relocateDetails.tocItem?.href ?? "")",
                    title: relocateDetails.tocItem?.label,
                    type: .book,
                    children: []
                )

                let locater = SRLocator(
                    type: .book,
                    title: relocateDetails.tocItem?.label ?? "",
                    locations: .init(
                        fragments: relocateDetails.cfi != nil ? ["cfi=\(relocateDetails.cfi!)"] : [],
                        totalProgression: relocateDetails.fraction,
                        position: relocateDetails.tocItem?.id
                    )
                )

                currentLocation = locater
                onRelocated.send(locater)
            }
        case .didTapHighlight:
            if let foliateHighlight = try? JSONDecoder().decode(TappedHighlight.self, from: message) {
                let cfi = foliateHighlight.value
                if let highlight = highlightsByCFI[cfi] {
                    selectedHighlight = highlight
                    editingActions.toggleRemoveHighlight(false)

                    let selection = SRSelection(
                        locator: highlight.locator,
                        frame: .init(
                            x: foliateHighlight.x,
                            y: foliateHighlight.y,
                            width: foliateHighlight.width,
                            height: foliateHighlight.height
                        )
                    )

                    editingActions.selection = selection
                    currentSelection = selection
                }
            }
        }
    }

    @MainActor
    public func setTheme() {
        theme.save()

        let script = """
        var _style = {
            lineHeight: \(theme.lineHeight),
            justify: \(theme.justify),
            hyphenate: \(theme.hyphenate),
            theme: {bg: "\(theme.bg.rawValue)", fg: "\(theme.fg.rawValue)", name: "\(theme.bg == .dark ? "dark" : "light")"},
            fontSize: \(theme.fontSize),
        }

        var _layout = {
           gap: \(theme.gap),
           maxInlineSize: \(theme.maxInlineSize),
           maxBlockSize: \(theme.maxBlockSize),
           maxColumnCount: \(theme.maxColumnCount),
           flow: \(theme.flow),
           animated: \(theme.animated),
           margin: \(theme.margin)
        }

        globalReader?.setTheme({style: _style, layout: _layout})
        """

        webView.evaluateJavaScript(script) { _, error in
            if let error {
                print("ERROR setting book theme: \(error)")
            }
        }
    }

    func getCfi(for locator: SRLocator) -> String? {
        for fragment in locator.locations.fragments {
            let optionalCfiParam = fragment
                .components(separatedBy: "#")
                .map { $0.components(separatedBy: "=") }
                .first { $0.first == "cfi" && $0.count == 2 }

            guard let cfiParam = optionalCfiParam else {
                return nil
            }

            return cfiParam[1]
        }

        return nil
    }

    private func clearWebViewSelection() {
        let script = """
        globalReader?.doc?.getSelection()?.removeAllRanges();
        """

        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(script)
        }
    }

    private var selectedHighlight: SRHighlight?
}

public extension EBookReaderViewModel {
    func removeHighlight(_ highlight: SRHighlight) {
        highlights.removeValue(forKey: highlight.id)

        guard let cfi = getCfi(for: highlight.locator) else { return }
        highlightsByCFI[cfi] = highlight

        let script = """
        globalReader?.removeAnnotation({index: \(highlight.locator.locations.position ?? 0), value: \"\(cfi)\"})
        """

        webView.evaluateJavaScript(script, in: nil, in: .page)
        onRemovedHighlight.send(highlight)
    }

    func editHighlight(_ highlight: SRHighlight, style: HighlightColor) {
        var modifiedHighlight = highlight

        removeHighlight(highlight)
        modifiedHighlight.color = style

        injectHighlight(modifiedHighlight)
        highlights[modifiedHighlight.id] = modifiedHighlight
        onHighlighted.send(modifiedHighlight)
    }

    func injectHighlight(_ highlight: SRHighlight) {
        guard let cfi = getCfi(for: highlight.locator) else { return }

        let script = """
        var hPromise = globalReader?.makeHighlightCFI("\(cfi)", "\(highlight.color.description)")

        await hPromise
        return hPromise
        """

        DispatchQueue.main.async {
            self.webView.callAsyncJavaScript(script, in: nil, in: .page) { result in
                switch result {
                case .success:
                    break
                case .failure:
                    break
                }
            }
        }

        selectedHighlight = highlight
        highlights[highlight.id] = highlight
        highlightsByCFI[cfi] = highlight

        clearWebViewSelection()
    }

    internal func setupActions() {
        var editingActions: [EditingAction] = ReaderEditingActions.allCases.compactMap {
            if $0 == .removeHighlight {
                return EditingAction(
                    title: ReaderEditingActions.removeHighlight.rawValue,
                    identifier: .init(ReaderEditingActions.removeHighlight.rawValue),
                    attributes: .hidden,
                    handler: editingActionHandler(_:)
                )
            }

            return EditingAction(
                title: $0.rawValue,
                identifier: .init($0.rawValue),
                handler: editingActionHandler(_:)
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

    internal func editingActionHandler(_ action: UIAction) {
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

    internal func highlightActionHandler(_ action: UIAction) {
        if let intType = Int(action.identifier.rawValue),
           let color = HighlightColor(rawValue: intType),
           let selectedHighlight = selectedHighlight
        {
            editHighlight(selectedHighlight, style: color)
        }

        selectedHighlight = nil
    }

    @MainActor
    func highlightSelection() {
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
}

public extension EBookReaderViewModel {
    func generateLinks() async -> [SRLink] {
        let script = """
        return JSON.stringify(globalReader?.book?.toc)
        """

        let tocJSON = try? await webView.callAsyncJavaScript(script, contentWorld: .page) as? String

        guard let tocJSONData = tocJSON?.data(using: .utf8) else {
            return []
        }

        let toc = try? JSONDecoder().decode([FoliateToc].self, from: tocJSONData)

        func node(from item: FoliateToc) -> SRLink? {
            return .init(
                href: "#cfi=\(item.href)",
                title: item.label,
                type: .book,
                children: nodes(in: item.subitems)
            )
        }

        func nodes(in children: [FoliateToc]?) -> [SRLink] {
            guard let children = children else {
                return []
            }

            return children.compactMap { node(from: $0) }
        }

        return nodes(in: toc)
    }

    func goForward() {
        let script = """
            globalReader?.view.next();
        """

        webView.evaluateJavaScript(script)
    }

    func goBackward() {
        let script = """
            globalReader?.view.prev();
        """

        webView.evaluateJavaScript(script)
    }

    // "#cfi=href"
    func goTo(for link: SRLink) {
        let fragments = link.href.split(separator: "#", maxSplits: 1).map(String.init)
        let fragment = fragments.indices.contains(0) ? fragments[0] : nil
        guard let cfi = fragment?.split(separator: "=").last.map(String.init) else {
            return
        }

        let script = """
        globalReader?.view.goTo("\(cfi)")
        """

        webView.evaluateJavaScript(script)
    }

    func goTo(for locater: SRLocator) {
        let fragments = locater.locations.fragments.split(separator: "#", maxSplits: 1).map(String.init)
        let fragment = fragments.indices.contains(0) ? fragments[0] : nil
        guard let cfi = fragment?.split(separator: "=").last.map(String.init) else {
            return
        }

        let script = """
        globalReader?.view.goTo("\(cfi)")
        """

        webView.evaluateJavaScript(script)
    }
}

public enum ReaderState: Equatable {
    public static func == (lhs: ReaderState, rhs: ReaderState) -> Bool {
        return lhs.reflectedValue == rhs.reflectedValue
    }

    case loading
    case ready
    case error(String)

    var reflectedValue: String { String(reflecting: self) }
}
