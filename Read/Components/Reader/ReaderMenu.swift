//
//  ReaderMenu.swift
//  Read
//
//  Created by Mirna Olvera on 2/12/24.
//

import SwiftUI

struct PDFReaderMenu: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.dismiss) var dismiss

    var book: Book
    @StateObject var viewModel: PDFReaderViewModel

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: Header

            HStack {
                VStack(alignment: .leading) {
                    Text(book.title)
                        .lineLimit(1)

                    Text(viewModel.currentLabel)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // MARK: Exit Button

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.accent)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: 58)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)

            Spacer()

            // MARK: Footer

            HStack(spacing: 12) {
                Spacer()

                // MARK: Contents Button

                Button {
                    viewModel.showContentSheet.toggle()
                }
                label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(Color.accent)
                        .font(.system(size: 20))
                }
                .padding(12)
                .background(.black)
                .clipShape(.circle)

                // MARK: Settings Button

                Button {
                    viewModel.showSettingsSheet.toggle()
                }
                label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.accent)
                        .font(.system(size: 20))
                }
                .padding(12)
                .background(.black)
                .clipShape(.circle)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: 58)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
        .padding(.top, safeAreaInsets.top)
        .padding(.bottom, safeAreaInsets.bottom)
        .padding(.leading, safeAreaInsets.leading)
        .padding(.trailing, safeAreaInsets.trailing)
    }
}

struct EBookReaderMenu: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.dismiss) var dismiss

    var book: Book
    @StateObject var viewModel: EBookReaderViewModel

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: Header

            HStack {
                VStack(alignment: .leading) {
                    Text(book.title)
                        .lineLimit(1)

                    Text(viewModel.currentLabel)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                Spacer()

                // MARK: Exit Button

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.accent)
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: 58)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)

            Spacer()

            // MARK: Footer

            HStack(spacing: 12) {
                Spacer()

                // MARK: Contents Button

                Button {
                    viewModel.showContentSheet.toggle()
                }
                label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(Color.accent)
                        .font(.system(size: 20))
                }
                .padding(12)
                .background(.black)
                .clipShape(.circle)

                // MARK: Settings Button

                Button {
                    viewModel.showSettingsSheet.toggle()
                }
                label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.accent)
                        .font(.system(size: 20))
                }
                .padding(12)
                .background(.black)
                .clipShape(.circle)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: 58)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
        .padding(.top, safeAreaInsets.top)
        .padding(.bottom, safeAreaInsets.bottom)
        .padding(.leading, safeAreaInsets.leading)
        .padding(.trailing, safeAreaInsets.trailing)
    }
}

#Preview {
    EBookReaderMenu(book: .example1, viewModel: EBookReaderViewModel())
}
