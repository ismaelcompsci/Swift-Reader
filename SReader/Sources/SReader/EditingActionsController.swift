//
//  File.swift
//
//
//  Created by Mirna Olvera on 5/26/24.
//

import Foundation
import UIKit

public final class EditingActionsController: NSObject {
    public var actions: [EditingAction]
    public var editMenuInteraction: UIEditMenuInteraction!
    public var addSuggestedActions = false

    public init(actions: [EditingAction], addSuggestesActions: Bool = true) {
        self.actions = actions
        self.addSuggestedActions = addSuggestesActions
        super.init()

        self.editMenuInteraction = UIEditMenuInteraction(delegate: self)
    }

    public var selection: SRSelection? {
        didSet {
            presentMenu()
        }
    }

    public func presentMenu() {
        guard let frame = selection?.frame else {
            return
        }

        editMenuInteraction.presentEditMenu(
            with: .init(
                identifier: "selection",
                sourcePoint: .init(
                    x: frame.midX,
                    y: frame.minY
                )
            )
        )
    }

    func canPerformAction(_ action: Selector) -> Bool {
        guard
            selection != nil,
            let _ = actions.first(where: { $0.action == action.description })
        else {
            return false
        }

        return true
    }

    func canPerformAction(_ action: EditingAction) -> Bool {
        canPerformAction(Selector(action.action))
    }

    // i dont like this
    private var stand: UIMenu?
    private var share: UIMenu?
    private var look: UIMenu?

    @available(iOS 13.0, *)
    func buildMenu(with builder: UIMenuBuilder) {
        stand = builder.menu(for: .standardEdit)
        share = builder.menu(for: .share)
        look = builder.menu(for: .lookup)

        builder.remove(menu: .lookup)
        builder.remove(menu: .share)
        builder.remove(menu: .learn)
        builder.remove(menu: .standardEdit)
    }

    @MainActor
    public func copy(_ selectionText: String? = nil) {
        guard let text = selection?.locator.text else {
            return
        }

        if let selectionText = selectionText {
            UIPasteboard.general.string = selectionText
        } else {
            UIPasteboard.general.string = text
        }
    }
}

extension EditingActionsController: UIEditMenuInteractionDelegate {
    public func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        menuFor configuration: UIEditMenuConfiguration,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        var items = [UIMenuElement]()

        items.append(contentsOf: actions
            .compactMap {
                $0.menuItem
            })

        if let stand = stand {
            items.append(stand)
        }

        if let share = share {
            items.append(share)
        }

        if let look = look {
            items.append(look)
        }

        return .init(
            children: items
        )
    }
}

public extension EditingActionsController {
    func toggleRemoveHighlight(_ hide: Bool) {
        if let index = actions.firstIndex(where: {
            $0.action == ReaderEditingActions.removeHighlight.rawValue
        }) {
            if hide == true {
                actions[index].menuItem?.attributes = .hidden
            } else {
                actions[index].menuItem?.attributes = .destructive
            }
        }
    }
}
