//
//  IridescentBackground.swift
//  阿默 —— 流动的全息玻璃背景
//

import SwiftUI

struct IridescentBackground: View {
    let palette: MoodPalette

    var body: some View {
        ZStack {
            // 略带冷调的底色，衬托全息光晕（原来的 0xF7F7FB 偏暖偏灰）
            Color(hex: 0xF4F5FB).ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                MeshGradient(
                    width: 3, height: 3,
                    points: Self.points(t),
                    colors: palette.mesh
                )
                .ignoresSafeArea()
                .blur(radius: 44)
                .opacity(1.0)
            }

            // 一层薄白纱，制造通透、磨砂的空气感（从 0.18 降到 0.10，不再压住色彩）
            Color.white.opacity(0.10).ignoresSafeArea()
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
