//
//  ReaderSettings.swift
//  Read
//
//  Created by Mirna Olvera on 3/5/24.
//

import SwiftUI

struct ReaderSettings: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appColor: AppColor
    
    @Binding var theme: Theme
    
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
                    .foregroundStyle(appColor.accent)
                }
                
                VStack(alignment: .center) {
                    // MARK: Reader Theme
                    
                    HStack {
                        ForEach(ThemeBackground.allCases) { themeBg in
                            ZStack {
                                Button {
                                    theme.bg = themeBg
                                    theme.fg = themeBg.fromBackground(background: themeBg)
                                    
                                    updateTheme?()
                                } label: {
                                    Image(systemName: "textformat")
                                }
                                .padding(14)
                                .background(Color(hex: themeBg.rawValue))
                                .clipShape(.circle)
                                .overlay {
                                    if themeBg == theme.bg {
                                        Circle()
                                            .stroke(appColor.accent, lineWidth: 1.0)
                                    }
                                }
                                .foregroundStyle(Color(hex: themeBg.fromBackground(background: themeBg).rawValue))
                                
                                if themeBg == theme.bg {
                                    Circle()
                                        .stroke(appColor.accent)
                                        .fill(appColor.accent)
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
                                theme.decreaseLineHeight()
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
                                theme.increaseLineHeight()
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
                                theme.decreaseFontSize()
                                updateTheme?()
                            } label: {
                                Image(systemName: "textformat.size.smaller")
                                    .font(.system(size: 24))
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                theme.increaseFontSize()
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
                                theme.decreaseGap()
                                updateTheme?()
                            } label: {
                                Image(systemName: "rectangle.portrait.arrowtriangle.2.outward")
                                    .font(.system(size: 24))
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                theme.increaseGap()
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
                                theme.increaseMargin()
                                updateTheme?()
                            } label: {
                                Image(systemName: "rectangle.compress.vertical")
                                    .font(.system(size: 24))
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                theme.decreaseMargin()
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
                                theme.setMaxColumnCount(1)
                                updateTheme?()
                            } label: {
                                Image(systemName: "square")
                                    .font(.system(size: 24))
                                    .foregroundStyle(theme.maxColumnCount == 1 ? appColor.accent : .white)
                            }
                            
                            Divider()
                                .frame(maxHeight: 24)
                            
                            Button {
                                theme.setMaxColumnCount(2)
                                updateTheme?()
                            } label: {
                                Image(systemName: "square.split.2x1")
                                    .font(.system(size: 24))
                                    .foregroundStyle(theme.maxColumnCount == 2 ? appColor.accent : .white)
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
    ReaderSettings(theme: .constant(Theme()), isPDF: false)
}
