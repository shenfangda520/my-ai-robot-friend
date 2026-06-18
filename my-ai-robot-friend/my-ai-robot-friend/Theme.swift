//
//  Theme.swift
//  阿默 —— 全息玻璃主题：情绪 → 配色
//

import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// 一套情绪配色：orb 用于发光球（鲜亮、有饱和度），mesh 用于背景光晕（淡），accent 用于按钮/高亮。
struct MoodPalette {
    let orb: [Color]   // 4 个鲜亮色
    let mesh: [Color]  // 9 个淡色，喂给 3×3 MeshGradient
    let accent: Color

    /// vivid = 光球用的鲜亮色；pale = 背景光晕用的淡色。
    static func make(vivid: [Color], pale: [Color], accent: Color) -> MoodPalette {
        let w = Color(hex: 0xFCFCFF)
        let mesh = [
            w,        pale[0], w,
            pale[1],  pale[2], pale[3],
            w,        pale[3], w,
        ]
        return MoodPalette(orb: vivid, mesh: mesh, accent: accent)
    }
}

extension Mood {
    /// 情绪 → 配色。背景与光球都用它。
    var palette: MoodPalette {
        if grumpiness > 65 {
            // 暴躁：暖红 / 橙 / 品红
            return .make(
                vivid: [Color(hex: 0xFF7A5C), Color(hex: 0xFF4D6D),
                        Color(hex: 0xFFB14E), Color(hex: 0xE0529E)],
                pale: [Color(hex: 0xFFC9B8), Color(hex: 0xFF9E86),
                       Color(hex: 0xF584A0), Color(hex: 0xFFBE8A)],
                accent: Color(hex: 0xFF5C47))
        }
        if energy < 30 {
            // 困倦：暗蓝 / 薰衣草 / 灰紫（偏冷、偏暗）
            return .make(
                vivid: [Color(hex: 0x8FA0D8), Color(hex: 0x9A8FD4),
                        Color(hex: 0x7FA8D6), Color(hex: 0xB6A9E0)],
                pale: [Color(hex: 0xCAD4EC), Color(hex: 0xC2B8E2),
                       Color(hex: 0xBFD0E6), Color(hex: 0xD8D2EC)],
                accent: Color(hex: 0x6E76B0))
        }
        if trust > 70 {
            // 信任/温柔：粉 / 桃 / 天蓝 / 薄荷
            return .make(
                vivid: [Color(hex: 0xFF8FC0), Color(hex: 0x86C8FF),
                        Color(hex: 0xC79CFF), Color(hex: 0xFFB37E)],
                pale: [Color(hex: 0xFFD6E8), Color(hex: 0xCFE6FF),
                       Color(hex: 0xE7D9FF), Color(hex: 0xFFE6D2)],
                accent: Color(hex: 0xFF6FA8))
        }
        // 默认：均衡的鲜亮全息
        return .make(
            vivid: [Color(hex: 0xFF93C9), Color(hex: 0x76BFFF),
                    Color(hex: 0xB28BFF), Color(hex: 0x6FE6C0)],
            pale: [Color(hex: 0xFFD3E6), Color(hex: 0xCFE6FF),
                   Color(hex: 0xE3D6FF), Color(hex: 0xCBF6E6)],
            accent: Color(hex: 0x8E7BFF))
    }
}
