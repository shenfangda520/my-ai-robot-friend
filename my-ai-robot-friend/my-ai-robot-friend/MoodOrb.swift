//
//  MoodOrb.swift
//  阿默 —— 发光全息光球（本体）
//

import SwiftUI

struct MoodOrb: View {
    let palette: MoodPalette
    var size: CGFloat = 180
    var active: Bool = false   // 打字/思考时更亮、脉动更快

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let breathe = 1 + 0.04 * sin(t * (active ? 2.4 : 1.1))
            let spin = Angle(degrees: (t * (active ? 26 : 12)).truncatingRemainder(dividingBy: 360))

            ZStack {
                // 外发光（双层，更通透）
                Circle()
                    .fill(palette.orb[1])
                    .frame(width: size * 1.3, height: size * 1.3)
                    .blur(radius: size * 0.34)
                    .opacity(active ? 0.6 : 0.45)
                Circle()
                    .fill(palette.orb[2])
                    .frame(width: size * 1.05, height: size * 1.05)
                    .blur(radius: size * 0.22)
                    .opacity(active ? 0.7 : 0.55)

                // 主体：多个偏移的彩色径向光斑，旋转叠加
                ZStack {
                    blob(palette.orb[0], offset: CGSize(width: -size * 0.16, height: -size * 0.18))
                    blob(palette.orb[1], offset: CGSize(width: size * 0.18, height: -size * 0.10))
                    blob(palette.orb[2], offset: CGSize(width: -size * 0.12, height: size * 0.18))
                    blob(palette.orb[3], offset: CGSize(width: size * 0.14, height: size * 0.16))
                }
                .rotationEffect(spin)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .blur(radius: size * 0.06)

                // 高光：左上角的白色反光，制造玻璃球质感
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.9), .clear],
                            center: .topLeading, startRadius: 0, endRadius: size * 0.5)
                    )
                    .frame(width: size, height: size)
                    .opacity(0.7)

                // 顶部白色细光圈（玻璃质感），不压暗边缘
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.85), .white.opacity(0.0), .white.opacity(0.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.2)
                    .frame(width: size, height: size)
            }
            .scaleEffect(breathe)
            .shadow(color: palette.accent.opacity(0.25), radius: 24, y: 8)
        }
        .frame(width: size * 1.2, height: size * 1.2)
        .animation(.easeInOut(duration: 1.0), value: palette.accent)
    }

    private func blob(_ color: Color, offset: CGSize) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.0)],
                    center: .center, startRadius: 0, endRadius: size * 0.42)
            )
            .frame(width: size * 0.85, height: size * 0.85)
            .offset(offset)
    }
}
