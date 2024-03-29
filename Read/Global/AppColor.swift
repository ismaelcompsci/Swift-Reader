//
//  AppColor.swift
//  Read
//
//  Created by Mirna Olvera on 3/10/24.
//

import Foundation
import SwiftUI

class AppColor: ObservableObject {
    @AppStorage("ThemeColor") var accent: Color = .accent
}
