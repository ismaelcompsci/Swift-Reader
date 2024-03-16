//
//  ReaderContextMenu.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

struct ReaderContextMenuButton: ButtonStyle {
    let width: CGFloat
    let height: CGFloat
    let backgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: width, height: height)
            .contentShape(.rect)
            .background(configuration.isPressed ? Color.secondary : Color.black)
    }
}

enum ContextMenuEvent {
    case highlight
    case copy
    case delete
    case lookup
}

struct ReaderContextMenu: View {
    @Binding var showContextMenu: Bool
    @Binding var editMode: Bool

    var height: CGFloat = 44
    var buttonSizeWidth: CGFloat = 44
    var buttonSizeHeight: CGFloat {
        height
    }

    var numberOfButtons: CGFloat = 2

    var position: CGPoint
    var onEvent: ((ContextMenuEvent) -> Void)?

    var delete: some View {
        Button {
            onEvent?(.delete)
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.red)
        }
    }

    var highlight: some View {
        Button {
            onEvent?(.highlight)
        }
        label: {
            Circle()
                .fill(.yellow)
                .frame(width: buttonSizeWidth / 2, height: buttonSizeHeight / 2)
        }
    }

    var copy: some View {
        Button {
            onEvent?(.copy)
        }
        label: {
            Image(systemName: "doc.on.doc.fill")
        }
    }

    var lookup: some View {
        Button {
            onEvent?(.lookup)
        } label: {
            Image(systemName: "character.magnify")
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
            .frame(width: 1, height: buttonSizeHeight / 2)
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
        .buttonStyle(ReaderContextMenuButton(width: buttonSizeWidth, height: buttonSizeHeight, backgroundColor: .black))
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .position(position)
    }
}

#Preview {
    ReaderContextMenu(showContextMenu: .constant(false), editMode: .constant(true), position: .init(x: 100, y: 300), onEvent: { print($0) })
        .background(.white)
}
