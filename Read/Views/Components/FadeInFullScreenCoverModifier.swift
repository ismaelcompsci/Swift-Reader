//
//  FadeInFullScreenCover.swift
//  Read
//
//  Created by Mirna Olvera on 6/23/24.
//

import SwiftUI

struct FadeInFullScreenCoverModifier<V: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let view: () -> V

    @State var isPresentedInternal = false

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: Binding<Bool>(
                get: { isPresented },
                set: { isPresentedInternal = $0 }
            )) {
                Group {
                    if isPresentedInternal {
                        view()
                            .transition(.opacity)
                            .onDisappear { isPresented = false }
                    }
                }
                .onAppear { isPresentedInternal = true }
                .presentationBackground(.clear)
            }
            .transaction {
                $0.disablesAnimations = true
            }
            .animation(.easeInOut(duration: 0.24), value: isPresentedInternal)
    }
}

extension View {
    func fadeInFullScreenCover<V: View>(
        isPresented: Binding<Bool>,
        content: @escaping () -> V
    ) -> some View {
        modifier(FadeInFullScreenCoverModifier(
            isPresented: isPresented,
            view: content
        ))
    }
}
