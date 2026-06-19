//
//  OnboardingView.swift
//  my-ai-robot-friend
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    private let palette = Mood().palette
    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            GenUIBackground(palette: palette)

            VStack(spacing: 0) {
                topBar

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        OnboardingPageView(page: item, palette: palette)
                            .tag(index)
                            .padding(.horizontal, 22)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(GenUIMotion.morph, value: page)

                bottomControls
            }
        }
        .preferredColorScheme(.light)
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                Text("阿默")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.black.opacity(0.58))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.58), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.76), lineWidth: 1))

            Spacer()

            Button("跳过") {
                onFinish()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.42))
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.42), in: Capsule())
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.black.opacity(0.58) : Color.black.opacity(0.14))
                        .frame(width: index == page ? 22 : 7, height: 7)
                        .animation(GenUIMotion.quick, value: page)
                }
            }

            Button {
                if page == pages.count - 1 {
                    onFinish()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(GenUIMotion.morph) {
                        page += 1
                    }
                }
            } label: {
                HStack {
                    Text(page == pages.count - 1 ? "开始使用" : "继续")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: page == pages.count - 1 ? "checkmark" : "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.16), in: Circle())
                }
                .foregroundStyle(.white)
                .padding(.leading, 18)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.82), in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 18, y: 9)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 18)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let palette: MoodPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 20)

            hero

            VStack(alignment: .leading, spacing: 12) {
                Text(page.eyebrow)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.40))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.52), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.72), lineWidth: 1))

                Text(page.title)
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.74))
                    .lineSpacing(2)
                    .minimumScaleFactor(0.84)

                Text(page.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.black.opacity(0.44))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.70),
                                    page.tint.opacity(0.22),
                                    palette.accentSoft.opacity(0.24),
                                    Color.white.opacity(0.40)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(Color.white.opacity(0.78), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.085), radius: 26, y: 13)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(page.tint.opacity(0.28))
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                    Image(systemName: page.symbol)
                        .font(.system(size: 76, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    page.tint.opacity(0.92),
                                    palette.accent.opacity(0.72)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: page.tint.opacity(0.25), radius: 18, y: 8)
                        .symbolEffect(.pulse, options: .repeating.speed(0.6))
                }

                OnboardingPreviewStrip(page: page)
            }
            .padding(22)
        }
        .frame(height: 300)
        .revealOnAppear()
    }
}

private struct OnboardingPreviewStrip: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(page.chips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.48))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.54), in: Capsule())
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text(page.prompt)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "mic.fill")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Color.black.opacity(0.46))
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.60), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.76), lineWidth: 1))
        }
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let chips: [String]
    let prompt: String

    static let all: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "Adaptive AI",
            title: "一个会跟着你变化的 AI 朋友",
            subtitle: "阿默会根据聊天、情绪和关系状态调整语气，不是固定模板的机器人。",
            symbol: "sparkles.rectangle.stack",
            tint: Color(hex: 0x86C8FF),
            chips: ["聊天", "复盘", "陪你想"],
            prompt: "今天我该先做哪件事？"
        ),
        OnboardingPage(
            eyebrow: "Memory",
            title: "它会记住重要的小事",
            subtitle: "你可以保存偏好、设定、共同经历，让之后的对话更像真的认识你。",
            symbol: "brain.head.profile",
            tint: Color(hex: 0xFFB37E),
            chips: ["偏好", "日期", "共同经历"],
            prompt: "记住我最近在准备一个项目"
        ),
        OnboardingPage(
            eyebrow: "Personality",
            title: "性格、头像、关系都能调",
            subtitle: "嘴硬一点、温柔一点、话少一点，都可以在资料页里慢慢调成你喜欢的样子。",
            symbol: "slider.horizontal.3",
            tint: Color(hex: 0xB28BFF),
            chips: ["毒舌", "温柔", "话痨"],
            prompt: "把你调成更像我的搭子"
        ),
        OnboardingPage(
            eyebrow: "Local First",
            title: "你的设定只保存在本机",
            subtitle: "API Key、记忆和个人信息都存在当前设备里；你随时可以在设置里清空。",
            symbol: "lock.shield",
            tint: Color(hex: 0x6FE6C0),
            chips: ["本机保存", "可清空", "可关闭"],
            prompt: "开始认识阿默"
        )
    ]
}
