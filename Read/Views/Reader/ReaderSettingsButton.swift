//
//  ReaderSettingsButton.swift
//  Read
//
//  Created by Mirna Olvera on 5/17/24.
//

import SwiftUI

enum ReaderSettingsAction: String, CaseIterable {
    case content
    case bookmarks
//    case search
    case settings

    var label: String {
        switch self {
        case .content:
            "Contents"
        case .bookmarks:
            "Bookmarks & Highlights"
//        case .search:
//            "Search Book"
        case .settings:
            "Themes & Settings"
        }
    }

    var icon: String {
        switch self {
        case .content:
            "list.bullet"
        case .bookmarks:
            "pencil.tip"
//        case .search:
//            "magnifyingglass"
        case .settings:
            "textformat.size"
        }
    }
}

struct ReaderSettingsButton: View {
    @Binding var show: Bool
    @State var showSettings = false
    @State var rows = [ReaderSettingsAction]()
    
    var onEvent: ((ReaderSettingsAction) -> Void)?
    
    func close() {
        for index in ReaderSettingsAction.allCases.indices.reversed() {
            let delay = 0.02 * Double((ReaderSettingsAction.allCases.count) - index)
            
            let _ = withAnimation(
                .interactiveSpring(
                    response: 0.13,
                    dampingFraction: 2,
                    blendDuration: 0.14
                ).delay(TimeInterval(delay))
            ) {
                if rows.isEmpty == true {
                    return
                }
                
                rows.remove(at: index)
            }
        }
        
        withAnimation {
            showSettings = false
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if showSettings == false && show {
                Button {
                    withAnimation {
                        showSettings = true
                    }
                            
                    for index in ReaderSettingsAction.allCases.indices {
                        let delay = 0.02 * Double(index)
                            
                        withAnimation(
                            .interactiveSpring(
                                response: 0.13,
                                dampingFraction: 2,
                                blendDuration: 0.14
                            ).delay(TimeInterval(delay))
                        ) {
                            rows.append(ReaderSettingsAction.allCases[index])
                        }
                    }
                            
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22))
                        .frame(width: 24, height: 24)
                }
                .padding(6)
                .background(.ultraThickMaterial)
                .clipShape(.rect(cornerRadius: 10))
                .tint(.primary)
                .transition(.scale.combined(with: .opacity))
            }
                    
            VStack {
                ForEach(rows, id: \.self) {
                    item in
                    let title = item.label
                    let image = item.icon
                            
                    Button {
                        onEvent?(item)
                        close()
                    } label: {
                        HStack {
                            Text(title)
                                    
                            Spacer()
                                    
                            Image(systemName: image)
                        }
                        .padding()
                        .background(.bar)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .tint(.primary)
                    .transition(
                        .blurReplace
                            .combined(
                                with: .scale(1.1, anchor: .bottomTrailing).combined(
                                    with: .move(
                                        edge: .trailing
                                    )
                                    .combined(with: .move(edge: .bottom))
                                )
                            )
                            .combined(with: .opacity)
                    )
                }
            }
            .frame(maxWidth: 300, alignment: .bottomTrailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing)
        .onChange(of: show) { _, new in
            if new == false {
                close()
            }
        }
    }
}

#Preview {
    VStack(alignment: .trailing) {
        Spacer()

        ReaderSettingsButton(show: .constant(true))
    }
    .preferredColorScheme(.dark)
}
