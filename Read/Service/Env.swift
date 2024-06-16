//
//  Env.swift
//  Read
//
//  Created by Mirna Olvera on 6/15/24.
//

import Foundation
import SwiftUI

@MainActor
public extension View {
    func withPreviewsEnv() -> some View {
        environment(Navigator())
            .environment(UserPreferences.shared)
            .environment(AppTheme.shared)
            .environment(UserPreferences.shared)
            .environment(Toaster.shared)
    }
}
