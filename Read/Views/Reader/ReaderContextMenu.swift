//
//  ReaderContextMenu.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

enum ContextMenuEvent {
    case highlight
    case copy
    case delete
    case lookup
}

struct ReaderContextMenu: View {
    @Binding var showContextMenu: Bool
    @Binding var editMode: Bool

    var buttonSize: CGFloat = 44

    var numberOfButtons: CGFloat = 2

    var position: CGPoint
    var onEvent: ((ContextMenuEvent) -> Void)?

    var delete: some View {
        Button {
            onEvent?(.delete)
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.red)
                .frame(width: buttonSize, height: buttonSize)
        }
    }

    var highlight: some View {
        Button {
            onEvent?(.highlight)
        }
        label: {
            Circle()
                .fill(.yellow)
                .frame(width: buttonSize / 2, height: buttonSize / 2)
                .frame(width: buttonSize, height: buttonSize)
        }
    }

    var copy: some View {
        Button {
            onEvent?(.copy)
        }
        label: {
            Image(systemName: "doc.on.doc.fill")
                .frame(width: buttonSize, height: buttonSize)
        }
    }

    var lookup: some View {
        Button {
            onEvent?(.lookup)
        } label: {
            Image(systemName: "character.magnify")
                .frame(width: buttonSize, height: buttonSize)
        }
    }

    var editMenu: some View {
        HStack(spacing: 0) {
            copy

            divider

            lookup

            divider

            delete
        }
    }

    var divider: some View {
        Divider()
            .frame(width: 1, height: buttonSize / 2)
    }

    var menu: some View {
        HStack(spacing: 0) {
            highlight

            divider

            lookup

            divider

            copy
        }
    }

    var body: some View {
        HStack {
            if editMode {
                editMenu
            } else {
                menu
            }
        }
        .tint(.primary)
        .background(.bar)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .position(position)
    }
}

#Preview {
    ReaderContextMenu(showContextMenu: .constant(false), editMode: .constant(true), position: .init(x: 100, y: 300), onEvent: { print($0) })
        .background(.white)
}
