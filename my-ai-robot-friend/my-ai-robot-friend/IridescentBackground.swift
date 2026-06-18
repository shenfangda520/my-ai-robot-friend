//
//  IridescentBackground.swift
//  阿默 —— 流动的全息玻璃背景
//

import SwiftUI

struct IridescentBackground: View {
    let palette: MoodPalette

    var body: some View {
        ZStack {
            Color(hex: 0xF7F7FB).ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                MeshGradient(
                    width: 3, height: 3,
                    points: Self.points(t),
                    colors: palette.mesh
                )
                .ignoresSafeArea()
                .blur(radius: 50)
                .opacity(0.9)
            }

            // 一层白纱，制造通透、磨砂的空气感
            Color.white.opacity(0.18).ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 1.2), value: palette.accent)
    }

    /// 让 3×3 网格的内部点缓慢做正弦漂移，四角固定。
    private static func points(_ t: TimeInterval) -> [SIMD2<Float>] {
        func osc(_ a: Double, _ speed: Double, _ phase: Double) -> Float {
            Float(a * sin(t * speed + phase))
        }
        return [
            SIMD2(0, 0),
            SIMD2(0.5 + osc(0.10, 0.30, 0), 0),
            SIMD2(1, 0),
            SIMD2(0, 0.5 + osc(0.10, 0.27, 1.5)),
            SIMD2(0.5 + osc(0.14, 0.23, 2.0), 0.5 + osc(0.14, 0.21, 0.5)),
            SIMD2(1, 0.5 + osc(0.10, 0.25, 3.0)),
            SIMD2(0, 1),
            SIMD2(0.5 + osc(0.10, 0.29, 4.0), 1),
            SIMD2(1, 1),
        ]
    }
}
