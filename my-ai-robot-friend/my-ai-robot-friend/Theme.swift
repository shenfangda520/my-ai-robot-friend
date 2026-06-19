//
//  Theme.swift
//  阿默 —— 全息玻璃主题：情绪 → 配色
//

import SwiftUI
import UIKit

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

    /// 解析 6 位十六进制字符串（如 "FF5C47"）。失败返回 nil。
    init?(hexString: String) {
        let s = hexString.trimmingCharacters(in: .whitespaces)
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(hex: v)
    }

    /// 转成 6 位十六进制字符串。
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X",
                      Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}

extension AppSettings {
    /// 自定义气泡颜色；未设置时返回 nil（表示跟随心情）。
    var bubbleColor: Color? {
        bubbleHex.isEmpty ? nil : Color(hexString: bubbleHex)
    }
}

/// 一套情绪配色：orb 用于发光球（鲜亮、有饱和度），mesh 用于背景光晕（淡），accent 用于按钮/高亮。
struct MoodPalette {
    let orb: [Color]   // 4 个鲜亮色
    let mesh: [Color]  // 9 个淡色，喂给 3×3 MeshGradient
    let accent: Color
    let accentDeep: Color  // 同色系更深一档，用于浮在彩色背景上的文字/按钮，保证对比度
    let accentSoft: Color  // 更淡一档，用于 chip / 选中态底色

    /// vivid = 光球用的鲜亮色；pale = 背景光晕用的淡色。
    /// mesh 9 格全部铺 pale 色（以前四角写死纯白 + pale[3] 重复，导致背景被稀释发白）。
    static func make(vivid: [Color], pale: [Color], accent: Color) -> MoodPalette {
        let mesh = [
            pale[1],  pale[0], pale[2],
            pale[0],  pale[2], pale[3],
            pale[2],  pale[3], pale[1],
        ]
        // accentDeep：把 accent 往暗里压一档（近似 ×0.7 亮度），文字才压得住彩色背景。
        // accentSoft：accent 叠白冲淡，做 chip 底色。
        return MoodPalette(orb: vivid, mesh: mesh, accent: accent,
                           accentDeep: accent.mixed(with: .black, by: 0.30),
                           accentSoft: accent.mixed(with: .white, by: 0.62))
    }
}

extension Color {
    /// 线性混色：把 self 与 other 按 amount 混合（amount∈[0,1]，1=完全变成 other）。
    /// 用于从单一 accent 派生 accentDeep / accentSoft，避免散落硬编码。
    func mixed(with other: Color, by amount: Double) -> Color {
        let a = CGFloat(min(max(amount, 0), 1))
        return Color(
            uiColor: UIColor(self).blended(with: other, fraction: a)
        )
    }
}

private extension UIColor {
    /// 和另一个颜色按 fraction 线性混合，返回非 alpha 预乘的 RGB 结果。
    func blended(with other: Color, fraction: CGFloat) -> UIColor {
        let o = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        o.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red:   r1 + (r2 - r1) * fraction,
            green: g1 + (g2 - g1) * fraction,
            blue:  b1 + (b2 - b1) * fraction,
            alpha: a1 + (a2 - a1) * fraction
        )
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
