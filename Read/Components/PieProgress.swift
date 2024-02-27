//
//  PieProgress.swift
//  Read
//
//  Created by Mirna Olvera on 2/10/24.
//

import SwiftUI

struct PieShape: Shape {
    var progress: Double = 0.0

    var animatableData: Double {
        get {
            progress
        }
        set {
            progress = newValue
        }
    }

    private let startAngle: Double = (Double.pi) * 1.5
    private var endAngle: Double {
        return startAngle + Double.pi * 2 * progress
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arcCenter = CGPoint(x: rect.size.width / 2, y: rect.size.width / 2)
        let radius = rect.size.width / 2
        path.move(to: arcCenter)
        path.addArc(center: arcCenter, radius: radius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct PieProgress: View {
    var progress: Double
    @EnvironmentObject var appColor: AppColor

    var body: some View {
        Circle()
            .fill(appColor.accent.opacity(0.4))
            .overlay(
                PieShape(progress: Double(self.progress))
                    .foregroundColor(appColor.accent.opacity(0.6))
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    PieProgress(progress: 0.24)
}
