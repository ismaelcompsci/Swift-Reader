//
//  ReaderSettings.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftReader
import SwiftUI

struct ReaderSettings: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppTheme.self) var theme
    
    @Binding var bookTheme: BookTheme
    
    var isPDF: Bool
    
    var updateTheme: (() -> Void)?
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(theme.tintColor)
                }
                
                VStack(alignment: .center) {
                    // MARK: Reader Theme
                    
                    HStack {
                        ForEach(ThemeBackground.allCases) { themeBg in
                            ZStack {
                                Button {
                                    bookTheme.bg = themeBg
                                    bookTheme.fg = themeBg.fromBackground(background: themeBg)
                                    
                                    updateTheme?()
                                } label: {
                                    Image(systemName: "textformat")
                                }
                                .padding(14)
                                .background(Color(hex: themeBg.rawValue))
                                .clipShape(.circle)
                                .overlay {
                                    if themeBg == bookTheme.bg {
                                        Circle()
                                            .stroke(theme.tintColor, lineWidth: 1.0)
                                    }
                                }
                                .foregroundStyle(Color(hex: themeBg.fromBackground(background: themeBg).rawValue))
                                
                                if themeBg == bookTheme.bg {
                                    Circle()
                                        .stroke(theme.tintColor)
                                        .fill(theme.tintColor)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 12, y: -18)
                                }
                            }
                        }
                    }
                    
                    if !isPDF {
                        // MARK: Reader Line Height
                        
                        HStack(spacing: 12) {
                            Button {
                                // decrease line height
                                bookTheme.decreaseLineHeight()
                                updateTheme?()
                            } label: {
                                Image(systemName: "blinds.horizontal.closed")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black)
                                    .font(.system(size: 24))
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                bookTheme.increaseLineHeight()
                                updateTheme?()
                            } label: {
                                Image(systemName: "blinds.horizontal.open")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black)
                                    .font(.system(size: 24))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: 74, maxHeight: 52)

                        // MARK: Reader Font Size
                        
                        HStack(spacing: 12) {
                            Button {
                                bookTheme.decreaseFontSize()
                                updateTheme?()
                            } label: {
                                Image(systemName: "textformat.size.smaller")
                                    .font(.system(size: 24))
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                bookTheme.increaseFontSize()
                                updateTheme?()
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
                                bookTheme.decreaseGap()
                                updateTheme?()
                            } label: {
                                Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
                                    .font(.system(size: 24))
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                bookTheme.increaseGap()
                                updateTheme?()
                            } label: {
                                Image(systemName: "rectangle.portrait.arrowtriangle.2.inward")
                                    .font(.system(size: 24))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: 74, maxHeight: 52)
                        
                        HStack {
                            Button {
                                bookTheme.increaseMargin()
                                updateTheme?()
                            } label: {
                                Image(systemName: "rectangle.compress.vertical")
                                    .font(.system(size: 24))
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                bookTheme.decreaseMargin()
                                updateTheme?()
                            } label: {
                                Image(systemName: "rectangle.expand.vertical")
                                    .font(.system(size: 24))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: 74, maxHeight: 52)
                        
                        HStack {
                            Button {
                                bookTheme.setMaxColumnCount(1)
                                updateTheme?()
                            } label: {
                                Image(systemName: "square")
                                    .font(.system(size: 24))
                                    .foregroundStyle(
                                        bookTheme.maxColumnCount == 1 ? theme.tintColor : .white
                                    )
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                bookTheme.setMaxColumnCount(2)
                                updateTheme?()
                            } label: {
                                Image(systemName: "square.split.2x1")
                                    .font(.system(size: 24))
                                    .foregroundStyle(
                                        bookTheme.maxColumnCount == 2 ? theme.tintColor : .white
                                    )
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: 74, maxHeight: 52)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            
            Spacer()
        }
        .presentationDetents([.height(300)])
        .background(.black)
    }
}

#Preview {
    ReaderSettings(bookTheme: .constant(BookTheme()), isPDF: false)
}
