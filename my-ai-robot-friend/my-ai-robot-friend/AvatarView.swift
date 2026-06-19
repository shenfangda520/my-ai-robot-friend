//
//  AvatarView.swift
//  阿默的“样子”——统一使用月光头像。
//

import SwiftUI

struct AvatarView: View {
    let imageData: Data?
    let palette: MoodPalette
    var size: CGFloat = 130
    var active: Bool = false

    var body: some View {
        MoonAvatarBadge(size: size, showGlow: true)
            .scaleEffect(active ? 1.035 : 1)
            .animation(GenUIMotion.quick, value: active)
    }
}
