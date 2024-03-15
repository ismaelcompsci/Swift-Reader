//
//  SideMenu.swift
//  Read
//
//  Created by Mirna Olvera on 3/15/24.
//

import Foundation
import SwiftUI

struct SideMenu<Menu: View>: ViewModifier {
    @Binding var isShowing: Bool
    let menu: () -> Menu

    init(isShowing: Binding<Bool>, @ViewBuilder menu: @escaping () -> Menu) {
        self._isShowing = isShowing
        self.menu = menu
    }

    public func body(content: Content) -> some View {
        return
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    content
                        .disabled(self.isShowing)
                        .frame(width: geometry.size.width, height: geometry.size.height)

                    self.menu()
                        .frame(width: geometry.size.width / 2)
                        .transition(.move(edge: .leading))
                        .offset(x: self.isShowing ? 0 : -geometry.size.width / 2 - geometry.safeAreaInsets.leading)
                }
            }
    }
}

extension View {
    func sideMenu<Menu: View>(
        isShowing: Binding<Bool>,
        @ViewBuilder menu: @escaping () -> Menu
    ) -> some View {
        self.modifier(SideMenu(isShowing: isShowing, menu: menu))
    }
}
