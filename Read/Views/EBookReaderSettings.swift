//
//  EBookReaderSettings.swift
//  Read
//
//  Created by Mirna Olvera on 2/7/24.
//

import SwiftUI

struct EBookReaderSettings: View {
    @StateObject var viewModel: ReaderViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()

                Button("Done") {
                    viewModel.showSettingsSheet.toggle()
                }
                .foregroundStyle(Color.accent)
            }

            VStack(alignment: .center) {
                // MARK: Reader Theme

                HStack {
                    ForEach(ThemeBackground.allCases) { themeBg in
                        ZStack {
                            Button {
                                viewModel.setReaderThemeBackground(themeBg)
                                viewModel.theme.fg = themeBg.fromBackground(background: themeBg)

                                viewModel.setTheme()
                            } label: {
                                Image(systemName: "textformat")
                            }
                            .padding(14)
                            .background(Color(hex: themeBg.rawValue))
                            .clipShape(.circle)
                            .foregroundStyle(Color(hex: themeBg.fromBackground(background: themeBg).rawValue))

                            if themeBg == viewModel.theme.bg {
                                Circle()
                                    .stroke(Color.accent)
                                    .fill(Color.accent)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -14, y: -18)
                            }
                        }
                    }
                }

                // MARK: Reader Font Size

                HStack(spacing: 12) {
                    Button {
                        viewModel.theme.decreaseFontSize()
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .font(.system(size: 24))
                    }

                    Divider()
                        .frame(maxHeight: 24)

                    Button {
                        viewModel.theme.increaseFontSize()
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .font(.system(size: 24))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: 74, maxHeight: 52)

                // MARK: Reader Gap Size

                HStack {
                    Button {
                        viewModel.theme.decreaseGap()
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
                            .font(.system(size: 24))
                    }

                    Divider()
                        .frame(maxHeight: 24)

                    Button {
                        viewModel.theme.increaseGap()
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "rectangle.portrait.arrowtriangle.2.inward")
                            .font(.system(size: 24))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: 74, maxHeight: 52)

                HStack {
                    Button {
                        viewModel.theme.decreaseBlockSize()
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "rectangle.compress.vertical")
                            .font(.system(size: 24))
                    }

                    Divider()
                        .frame(maxHeight: 24)

                    Button {
                        viewModel.theme.increaseBlockSize()
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "rectangle.expand.vertical")
                            .font(.system(size: 24))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: 74, maxHeight: 52)

                HStack {
                    Button {
                        viewModel.theme.setMaxColumnCount(1)
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "square")
                            .font(.system(size: 24))
                            .foregroundStyle(viewModel.theme.maxColumnCount == 1 ? Color.accent : .white)
                    }

                    Divider()
                        .frame(maxHeight: 24)

                    Button {
                        viewModel.theme.setMaxColumnCount(2)
                        viewModel.setTheme()
                    } label: {
                        Image(systemName: "square.split.2x1")
                            .font(.system(size: 24))
                            .foregroundStyle(viewModel.theme.maxColumnCount == 2 ? Color.accent : .white)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: 74, maxHeight: 52)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()

        Spacer()
    }
}

#Preview {
    EBookReaderSettings(viewModel: ReaderViewModel())
}
