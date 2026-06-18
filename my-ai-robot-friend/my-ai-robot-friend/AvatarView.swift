//
//  AvatarView.swift
//  阿默的“样子”——可插拔头像。
//
//  现在支持：① 自定义图片头像 ② 默认情绪光球。
//  以后接 3D 人脸模型时，只要在这里加一个分支（SceneKit / RealityKit），
//  其余界面无需改动——所有地方都用 AvatarView 显示形象。
//

import SwiftUI

struct AvatarView: View {
    let imageData: Data?
    let palette: MoodPalette
    var size: CGFloat = 130
    var active: Bool = false

    var body: some View {
        if let imageData, let ui = UIImage(data: imageData) {
            // 图片头像：仍保留情绪辉光，跟着心情变色
            ZStack {
                Circle()
                    .fill(palette.orb[1])
                    .frame(width: size * 1.25, height: size * 1.25)
                    .blur(radius: size * 0.3)
                    .opacity(active ? 0.6 : 0.45)
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1.5))
                    .shadow(color: palette.accent.opacity(0.25), radius: 20, y: 8)
            }
            .frame(width: size * 1.2, height: size * 1.2)
        } else {
            // 默认：情绪光球
            MoodOrb(palette: palette, size: size, active: active)
        }

        // 未来：3D 人脸模型分支放这里
        // else if let model = modelURL { SceneKitFaceView(url: model, mood: ...) }
    }
}
