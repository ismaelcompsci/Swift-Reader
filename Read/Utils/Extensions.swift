//
//  Extensions.swift
//  Read
//
//  Created by Mirna Olvera on 1/27/24.
//

import Foundation
import SwiftUI

// https://stackoverflow.com/a/43250864
public extension Data {
    var fileExtension: String {
        var values = [UInt8](repeating: 0, count: 1)
        self.copyBytes(to: &values, count: 1)

        let ext: String
        switch values[0] {
        case 0xFF:
            ext = ".jpg"
        case 0x89:
            ext = ".png"
        case 0x47:
            ext = ".gif"
        case 0x49, 0x4D:
            ext = ".tiff"
        default:
            ext = ".png"
        }
        return ext
    }
}

extension URL {
    var size: Double {
        let _ = self.startAccessingSecurityScopedResource()
        let attributes = try? FileManager.default.attributesOfItem(atPath: self.path)
        let size = attributes?[.size] as? Double ?? Double.random(in: 1...200)
        defer {
            self.stopAccessingSecurityScopedResource()
        }
        return size
    }
}

let htmlReplaceString: String = "<[^>]+>"
extension String {
    /**
     Takes the current String struct and strips out HTML using regular expression. All tags get stripped out.

     :returns: String html text as plain text
     */
    func stripHTML() -> String {
        return self.replacingOccurrences(of: htmlReplaceString, with: "", options: .regularExpression)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@MainActor
func showShareSheet(url: URL) {
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    UIApplication.shared.currentUIWindow()?.rootViewController?.present(activityVC, animated: true, completion: nil)
}

// utility extension to easily get the window
public extension UIApplication {
    func currentUIWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }

        let window = connectedScenes.first?
            .windows
            .first { $0.isKeyWindow }

        return window
    }
}

// https://dallinjared.medium.com/swiftui-tutorial-contrasting-text-over-background-color-2e7af57c1b20
extension Text {
    func getContrastText(backgroundColor: Color) -> some View {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(backgroundColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.6 ? self.foregroundColor(.white) : self.foregroundColor(.black)
    }
}

extension Color {
    static func random() -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: 1
        )
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
