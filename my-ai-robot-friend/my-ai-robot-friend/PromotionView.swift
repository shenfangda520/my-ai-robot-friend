//
//  PromotionView.swift
//  阿默 —— 推广页：展示宣传海报 + 一键分享
//

import SwiftUI
import UIKit

struct PromotionView: View {
    @ObservedObject var store: ChatStore
    private var palette: MoodPalette { store.mood.palette }

    /// 把 GPT 生成的海报命名为 PromoPoster 拖进 Assets，这里就会显示。
    private var poster: UIImage? { UIImage(named: "PromoPoster") }

    var body: some View {
        NavigationStack {
            RobotPage(palette: palette) {
                GlassPageHeader(
                    systemImage: "megaphone.fill",
                    title: "推广\(store.persona.name)",
                    subtitle: "把这张海报分享给朋友，让更多人认识\(store.persona.name)。",
                    palette: palette
                )

                if let poster {
                    posterCard(poster)
                    shareButton(poster)
                } else {
                    emptyCard
                }
            }
            .navigationTitle("推广")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func posterCard(_ ui: UIImage) -> some View {
        Image(uiImage: ui)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 22, y: 12)
    }

    private func shareButton(_ ui: UIImage) -> some View {
        ShareLink(
            item: Image(uiImage: ui),
            preview: SharePreview("\(store.persona.name) · AI 室友", image: Image(uiImage: ui))
        ) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .bold))
                Text("分享海报")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.84), in: Capsule())
            .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text("还没有海报")
                .font(.system(size: 16, weight: .semibold))
            Text("用 GPT 生成海报后，命名为 “PromoPoster” 拖进 Assets，这里就会自动显示并可分享。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
    }
}
