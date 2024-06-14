//
//  Toaster.swift
//  Read
//
//  Created by Mirna Olvera on 4/9/24.
//

import SwiftUI

@MainActor
@Observable public class Toaster {
    public static let shared = Toaster()

    func presentToast(message: String, type: ToastType) {
        ToastPresenter().show(toast: message, type: type)
    }
}

@MainActor
class ToastPresenter {
    private var toastWindow: UIWindow?

    func show(toast: String, type: ToastType) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return
        }
        toastWindow = UIWindow(windowScene: scene)
        toastWindow?.backgroundColor = .clear

        let windowHeight = toastWindow?.screen.bounds.height ?? -200
        let windowWidth = toastWindow?.screen.bounds.width ?? 300
        let safeBottom = toastWindow?.safeAreaInsets.bottom ?? 24
        let toastHeight: CGFloat = 78

        let toastWidth = windowWidth * 0.76
        let toastXPosition = (windowWidth / 2) - (toastWidth / 2)
        let initialToastPosition = windowHeight + toastHeight
        let destinationToastPosition = windowHeight - toastHeight - safeBottom

        // Start with the window off-screen at the top
        toastWindow?.frame = CGRect(
            x: toastXPosition,
            y: initialToastPosition,
            width: toastWidth,
            height: toastHeight
        )

        let view = Text(toast)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(type.color)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.13), lineWidth: 2)
            }
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 6)
            .shadow(radius: 8, y: 8)
            .font(.system(size: 12, weight: .medium))
            .lineLimit(2)
            .frame(height: 84)

        let hosting = UIHostingController(rootView: view)

        toastWindow?.rootViewController = hosting
        toastWindow?.rootViewController?.view.backgroundColor = .clear
        toastWindow?.makeKeyAndVisible()

        // Animate the window sliding down
        UIView.animate(withDuration: 0.5,
                       animations: {
                           self.toastWindow?.frame = CGRect(
                               x: toastXPosition,
                               y: destinationToastPosition,
                               width: toastWidth,
                               height: toastHeight
                           )
                       })

        // Hide the toast automatically after 2 seconds with slide up animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 0.5,
                           animations: {
                               self.toastWindow?.frame = CGRect(
                                   x: toastXPosition,
                                   y: initialToastPosition,
                                   width: toastWidth,
                                   height: toastHeight
                               )
                           }) { _ in
                self.toastWindow?.isHidden = true
                self.toastWindow = nil
            }
        }
    }
}

enum ToastType {
    case error
    case info
    case message

    var systemName: String {
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
