//
//  Toaster.swift
//  Read
//
//  Created by Mirna Olvera on 4/9/24.
//

import SimpleToast
import SwiftUI

@Observable
public class Toaster {
    public static let shared = Toaster()

    enum ToastType {
        case error
        case info
        case message

        var image: String {
            switch self {
            case .error:
                "exclamationmark.circle"
            case .info:
                "info.circle"
            case .message:
                "message.circle"
            }
        }

        var color: Color {
            switch self {
            case .error:
                .red
            case .info:
                .gray
            case .message:
                .green
            }
        }
    }

    var showToast: Bool = false
    var toastMessage: String = ""
    var toastImage: String = ""
    var toastColor: Color = .green
    var hideAfter: TimeInterval = 5

    var toastSettings: SimpleToastOptions {
        return SimpleToastOptions(alignment: .bottom, hideAfter: hideAfter)
    }

    func dismiss() {
        toastMessage = ""
        showToast = false
    }

    func presentToast(message: String, type: ToastType) {
        DispatchQueue.main.async {
            self.toastMessage = message
            self.toastImage = type.image
            self.toastColor = type.color
            self.showToast = true
        }
    }
}
