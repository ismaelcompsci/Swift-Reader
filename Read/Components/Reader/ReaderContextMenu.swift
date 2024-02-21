//
//  ReaderContextMenu.swift
//  Read
//
//  Created by Mirna Olvera on 2/15/24.
//

import SwiftUI

struct ReaderContextMenu: View {
    @StateObject var viewModel: ReaderViewModel
    @Binding var showContextMenu: Bool

    var height: CGFloat = 44
    var buttonSizeWidth: CGFloat = 44
    var buttonSizeHeight: CGFloat {
        height
    }

    var numberOfButtons: CGFloat = 2

    var position: CGPoint

    var body: some View {
        HStack {
            Button {
                viewModel.highlightSelection()
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
                viewModel.copySelection()
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
    ReaderContextMenu(viewModel: ReaderViewModel(url: URL(string: "")!, pdfHighlights: []), showContextMenu: .constant(false), position: .zero)
}
