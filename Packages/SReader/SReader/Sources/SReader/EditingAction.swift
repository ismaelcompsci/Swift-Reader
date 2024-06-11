//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/26/24.
//

import Foundation
import PDFKit
import UIKit

// https://github.com/readium/swift-toolkit/blob/595037da028249bbdf491a05ee8121c7d1de46ec/Sources/Navigator/EditingAction.swift#L19
public struct EditingAction: Hashable {
    enum Kind: Hashable {
        case native(String)
        case custom(UIAction)
    }

    let kind: Kind

    var action: String {
        switch kind {
        case let .native(action):
            return action
        case let .custom(item):
            return item.identifier.rawValue
        }
    }

    var menuItem: UIAction? {
        switch kind {
        case .native:
            return nil
        case let .custom(item):
            return item
        }
    }

    public init(title: String, handler: @escaping UIActionHandler) {
        self.kind = .custom(UIAction(title: title, handler: handler))
    }

    public init(
        title: String = "",
        subtitle: String? = nil,
        image: UIImage? = nil,
        selectedImage: UIImage? = nil,
        identifier: UIAction.Identifier? = nil,
        discoverabilityTitle: String? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off,
        handler: @escaping UIActionHandler
    ) {
        self.kind = .custom(UIAction(
            title: title,
            subtitle: subtitle,
            image: image,
            selectedImage: selectedImage,
            identifier: identifier,
            discoverabilityTitle: discoverabilityTitle,
            attributes: attributes,
            state: state,
            handler: handler
        ))
    }

    init(kind: Kind) {
        self.kind = kind
    }

    public static var defaultActions: [EditingAction] {
        [copy, share, define, lookup, translate]
    }

    public static let copy = EditingAction(kind: .native("copy:"))
    public static let lookup = EditingAction(kind: .native("_lookup:"))
    public static let define = EditingAction(kind: .native("_define:"))
    public static let translate = EditingAction(kind: .native("_translate:"))
    public static let share = EditingAction(kind: .native("_share:"))
}

public enum ReaderEditingActions: String, CaseIterable {
    case highlight = "Highlight"
    case removeHighlight = "Remove Highlight"
}

public enum HighlightColor: Int, CaseIterable, Identifiable, Codable {
    case yellow, green, blue, pink, purple, underline

    public var id: Int {
        rawValue
    }

    public var description: String {
        switch self {
        case .yellow:
            return "Yellow"
        case .green:
            return "Green"
        case .blue:
            return "Bue"
        case .pink:
            return "Pink"
        case .underline:
            return "Underline"
        case .purple:
            return "Purple"
        }
    }

    public var color: UIColor {
        switch self {
        case .yellow:
            .systemYellow
        case .green:
            .systemGreen
        case .blue:
            .systemBlue.withAlphaComponent(0.7)
        case .pink:
            .systemPink.withAlphaComponent(0.7)
        case .purple:
            .systemIndigo.withAlphaComponent(0.7)
        case .underline:
            .systemRed
        }
    }

    public var hex: String {
        color.toHex() ?? "#FFFF00"
    }
}

public extension HighlightColor {
    var pdfAnnotationSubtype: (PDFAnnotationSubtype, UIColor) {
        switch self {
        case .underline:
            return (.underline, .systemRed)
        case .yellow:
            return (.highlight, .systemYellow)
        case .green:
            return (.highlight, .systemGreen)
        case .blue:
            return (.highlight, .systemBlue.withAlphaComponent(0.7))
        case .pink:
            return (.highlight, .systemPink.withAlphaComponent(0.7))
        case .purple:
            return (.highlight, .systemIndigo.withAlphaComponent(0.7))
        }
    }
}
