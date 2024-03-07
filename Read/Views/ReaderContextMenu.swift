//
//  ReaderContextMenu.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

struct ReaderContextMenu: View {
    @Binding var showContextMenu: Bool

    var height: CGFloat = 44
    var buttonSizeWidth: CGFloat = 44
    var buttonSizeHeight: CGFloat {
        height
    }

    var numberOfButtons: CGFloat = 2

    var position: CGPoint
    var highlightButtonPressed: (() -> Void)?
    var copyButtonPressed: (() -> Void)?

    var body: some View {
        HStack {
            Button {
//                viewModel.highlightSelection()
                highlightButtonPressed?()
                showContextMenu.toggle()
            }
            label: {
                Circle()
                    .fill(.yellow)
                    .frame(width: buttonSizeWidth / 2, height: buttonSizeHeight / 2)
            }
            .frame(width: buttonSizeWidth, height: buttonSizeHeight)
            .background(.black)

            Divider()
                .frame(height: buttonSizeHeight / 2)

            Button {
//                viewModel.copySelection()
                copyButtonPressed?()
                showContextMenu.toggle()
            }

            label: {
                Image(systemName: "doc.on.doc.fill")
            }
            .frame(width: buttonSizeWidth, height: buttonSizeHeight)
            .background(.black)
        }
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .frame(width: buttonSizeWidth * numberOfButtons, height: buttonSizeHeight)
        .position(position)
        .onAppear {
            // TODO: change this
            //            viewModel.frame.width = buttonSizeWidth * numberOfButtons
            //            viewModel.frame.height = buttonSizeHeight
        }
    }
}

#Preview {
    ReaderContextMenu(showContextMenu: .constant(false), position: .zero)
}
