//
//  PDFReaderContextMenu.swift
//  Read
//
//  Created by Mirna Olvera on 2/15/24.
//

import SwiftUI
//
// struct PDFReaderContextMenu: View {
//    @StateObject var viewModel: PDFReaderViewModel
//
//    var height: CGFloat = 44
//    var buttonSizeWidth: CGFloat = 44
//    var buttonSizeHeight: CGFloat {
//        height
//    }
//
//    var numberOfButtons: CGFloat = 2
//
//    var body: some View {
//        HStack {
//            Button {
//                viewModel.highlightSelection()
//            }
//            label: {
//                Circle()
//                    .fill(.yellow)
//                    .frame(width: buttonSizeWidth / 2, height: buttonSizeHeight / 2)
//            }
//            .frame(width: buttonSizeWidth, height: buttonSizeHeight)
//            .background(.black)
//
//            Divider()
//                .frame(height: buttonSizeHeight / 2)
//
//            Button {
//                viewModel.copySelection()
//            }
//            label: {
//                Image(systemName: "doc.on.doc.fill")
//            }
//            .frame(width: buttonSizeWidth, height: buttonSizeHeight)
//            .background(.black)
//        }
//        .background(.black)
//        .clipShape(RoundedRectangle(cornerRadius: 4))
//        .frame(width: buttonSizeWidth * numberOfButtons, height: buttonSizeHeight)
//        .position(viewModel.position)
//        .onAppear {
//            // TODO: change this
//            viewModel.frame.width = buttonSizeWidth * numberOfButtons
//            viewModel.frame.height = buttonSizeHeight
//        }
//    }
// }
//
// #Preview {
//    PDFReaderContextMenu(viewModel: PDFReaderViewModel(url: URL(string: "")!))
// }
