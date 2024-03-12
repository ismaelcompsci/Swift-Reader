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

    var editMenu: some View {
        VStack {
            Button {
                onEvent?(.delete)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(ReaderContextMenuButton(width: buttonSizeWidth, height: buttonSizeHeight, backgroundColor: .black))
        }
    }

    var menu: some View {
        VStack {
            HStack(spacing: 0) {
                Button {
                    onEvent?(.highlight)
                }
                label: {
                    Circle()
                        .fill(.yellow)
                        .frame(width: buttonSizeWidth / 2, height: buttonSizeHeight / 2)
                }
                .buttonStyle(ReaderContextMenuButton(width: buttonSizeWidth, height: buttonSizeHeight, backgroundColor: .black))

                Divider()
                    .frame(width: 1, height: buttonSizeHeight / 2)

                Button {
                    onEvent?(.copy)
                }
                label: {
                    Image(systemName: "doc.on.doc.fill")
                }
                .buttonStyle(ReaderContextMenuButton(width: buttonSizeWidth, height: buttonSizeHeight, backgroundColor: .black))
            }
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
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .position(position)
    }
}

#Preview {
    ReaderContextMenu(showContextMenu: .constant(false), editMode: .constant(true), position: .init(x: 100, y: 300), onEvent: { print($0) })
        .background(.white)
}
