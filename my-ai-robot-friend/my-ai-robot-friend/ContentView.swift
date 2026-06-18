//
//  ContentView.swift
//  阿默 —— 聊天页（全息玻璃）
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var store: ChatStore
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    private var palette: MoodPalette { store.mood.palette }
    private var isHero: Bool { store.messages.count <= 1 }
    private var isComposing: Bool { inputFocused || !input.isEmpty }

    var body: some View {
        ZStack {
            IridescentBackground(palette: palette)
            VStack(spacing: 0) {
                header
                if isHero {
                    heroHome
                } else {
                    orbHeader
                    messageList
                }
                inputBar
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: isHero)
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: isComposing)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    inputFocused = false
                }
            } label: {
                Image(systemName: isComposing ? "xmark" : "wand.and.stars")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.78))
                    .frame(width: 34, height: 34)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.62), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: -8) {
                MiniMoodDot(color: palette.orb[0], symbol: "bolt.fill")
                MiniMoodDot(color: palette.orb[1], symbol: "heart.fill")
                MiniMoodDot(color: palette.orb[2], symbol: "sparkle")
            }

            Button { } label: {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.black.opacity(0.82)))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var orbHeader: some View {
        VStack(spacing: 8) {
            AvatarView(imageData: store.avatarData,
                       palette: palette,
                       size: isHero ? 160 : 86,
                       active: store.isSending)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isHero)
            Text(store.isSending ? "\(store.persona.name)正在想…" : "\(store.persona.name) · \(store.mood.statusLabel)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, isHero ? 24 : 10)
        .padding(.bottom, 6)
    }

    private var heroHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroGreeting

                ZStack {
                    AmbientOrbitView(palette: palette, active: store.isSending || isComposing)
                        .frame(height: isComposing ? 245 : 215)
                        .frame(maxWidth: .infinity)
                        .opacity(isComposing ? 1 : 0.92)

                    if isComposing {
                        VStack(spacing: 8) {
                            Text("\(store.persona.name)，我想问你")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text(input.isEmpty ? "从哪件事开始？" : "我听着。")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .padding(.top, isComposing ? 4 : 0)

                if !isComposing {
                    DailyBriefCard(store: store, palette: palette, submit: sendPreset)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                SuggestionRail(items: suggestions, palette: palette, action: sendPreset)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
    }

    private var heroGreeting: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(dateLine)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(greeting)，\(displayName)")
                .font(.system(size: 31, weight: .regular))
                .foregroundStyle(.primary)
            Text(store.isSending ? "\(store.persona.name)正在想。" : "\(store.persona.name)在这儿，\(store.mood.statusLabel)。")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(isHero ? [] : store.messages) { m in
                        GlassBubble(text: m.content, isUser: m.isUser,
                                    accent: palette.accent, tts: store.settings.ttsEnabled)
                            .id(m.id)
                    }
                    if store.isSending { TypingBubble().id("typing") }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .onChange(of: store.messages.count) { _, _ in scrollToEnd(proxy) }
            .onChange(of: store.isSending) { _, _ in scrollToEnd(proxy) }
        }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if store.isSending {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = store.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("跟\(store.persona.name)说点什么…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 16))
                .focused($inputFocused)
                .padding(.leading, 18)
                .padding(.trailing, 42)
                .padding(.vertical, 13)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(alignment: .trailing) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 18)
                }
                .overlay(Capsule().stroke(isComposing ? palette.accent.opacity(0.42) : .white.opacity(0.62), lineWidth: 1))
                .shadow(color: .black.opacity(isComposing ? 0.10 : 0.04), radius: isComposing ? 18 : 8, y: isComposing ? 9 : 4)
                .onSubmit(submit)

            Button(action: submit) {
                Image(systemName: canSend ? "arrow.up" : "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(canSend ? .white : .primary.opacity(0.72))
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(canSend ? Color.black : Color.white.opacity(0.58))
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .overlay(Circle().stroke(.white.opacity(canSend ? 0.0 : 0.66), lineWidth: 1))
                    .shadow(color: .black.opacity(canSend ? 0.18 : 0.06), radius: 14, y: 7)
            }
            .disabled(!canSend)
            .scaleEffect(canSend ? 1.0 : 0.96)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: canSend)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var canSend: Bool {
        !store.isSending && !input.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() {
        let text = input
        input = ""
        inputFocused = false
        Task { await store.send(text) }
    }

    private func sendPreset(_ text: String) {
        input = ""
        inputFocused = false
        Task { await store.send(text) }
    }

    private var displayName: String {
        let preferred = store.persona.userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !preferred.isEmpty { return preferred }
        let userName = store.user.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userName.isEmpty { return userName }
        return "我在"
    }

    private var suggestions: [String] {
        [
            "今天我该先做哪件事？",
            "陪我整理一下脑子",
            "给我一句不敷衍的鼓励",
            "记住一件关于我的事"
        ]
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: return "早上好"
        case 11..<14: return "中午好"
        case 14..<18: return "下午好"
        case 18..<23: return "晚上好"
        default: return "夜深了"
        }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }
}

// MARK: - 首页组件

private struct MiniMoodDot: View {
    let color: Color
    let symbol: String

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.9))
            Circle()
                .fill(.white.opacity(0.28))
                .blur(radius: 4)
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 28, height: 28)
        .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 1.2))
        .shadow(color: color.opacity(0.22), radius: 9, y: 4)
    }
}

private struct AmbientOrbitView: View {
    let palette: MoodPalette
    var active: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let speed = active ? 34.0 : 18.0
            let breathe = 1 + 0.035 * sin(t * (active ? 2.0 : 1.0))

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    palette.orb[i].opacity(0.0),
                                    palette.orb[i].opacity(0.78),
                                    .white.opacity(0.88),
                                    palette.orb[(i + 1) % palette.orb.count].opacity(0.56),
                                    palette.orb[i].opacity(0.0)
                                ],
                                center: .center
                            ),
                            lineWidth: i == 0 ? 11 : 8
                        )
                        .frame(width: CGFloat(144 + i * 42), height: CGFloat(144 + i * 42))
                        .blur(radius: CGFloat(i * 2))
                        .rotationEffect(.degrees(t * speed * (i.isMultiple(of: 2) ? 1 : -1) + Double(i * 52)))
                        .opacity(i == 2 ? 0.45 : 0.72)
                }

                MoodOrb(palette: palette, size: active ? 78 : 66, active: active)
                    .scaleEffect(breathe)

                orbitDot(color: palette.orb[0], size: 14, radius: 72, angle: t * 1.2)
                orbitDot(color: palette.orb[2], size: 22, radius: 104, angle: -t * 0.95 + 1.7)
                orbitDot(color: palette.orb[3], size: 10, radius: 126, angle: t * 0.74 + 3.2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .fill(.white.opacity(0.17))
                    .blur(radius: 24)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 20)
            }
        }
        .accessibilityHidden(true)
    }

    private func orbitDot(color: Color, size: CGFloat, radius: CGFloat, angle: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.96), color.opacity(0.9), color.opacity(0.08)],
                    center: .topLeading,
                    startRadius: 1,
                    endRadius: size
                )
            )
            .frame(width: size, height: size)
            .offset(x: cos(angle) * radius, y: sin(angle) * radius * 0.58)
            .shadow(color: color.opacity(0.48), radius: 18, y: 7)
    }
}

private struct DailyBriefCard: View {
    @ObservedObject var store: ChatStore
    let palette: MoodPalette
    let submit: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("今日同步", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(store.intimacyLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.78))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.46), in: Capsule())
            }

            Text(openingLine)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                MetricPill(title: "精力", value: store.mood.energy, color: palette.orb[1])
                MetricPill(title: "信任", value: store.mood.trust, color: palette.orb[0])
                MetricPill(title: "脾气", value: store.mood.grumpiness, color: palette.orb[2])
            }

            Button {
                submit("用你现在的状态，帮我规划一下今天。")
            } label: {
                HStack {
                    Text("开始今日对齐")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                        .background(Color.black.opacity(0.08), in: Circle())
                }
                .foregroundStyle(.primary)
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .background(.white.opacity(0.42), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.64), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 24, y: 14)
    }

    private var openingLine: String {
        if store.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "先把 API Key 填好，我就能从摆设升级成嘴硬室友。"
        }
        if store.mood.energy < 30 {
            return "\(store.persona.name)今天有点没电，但还能陪你把重要的事拎出来。"
        }
        if store.mood.grumpiness > 65 {
            return "\(store.persona.name)现在有点炸毛，适合处理难题，不太适合客套。"
        }
        return "\(store.persona.name)在线，适合聊天、复盘、记事，或者把乱糟糟的想法理顺。"
    }
}

private struct MetricPill: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Capsule()
                    .fill(color.opacity(0.78))
                    .frame(width: max(10, CGFloat(value) * 0.32), height: 5)
                    .background(Color.black.opacity(0.08), in: Capsule())
                Text("\(value)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.white.opacity(0.36), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SuggestionRail: View {
    let items: [String]
    let palette: MoodPalette
    let action: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 9) {
                ForEach(items, id: \.self) { item in
                    Button {
                        action(item)
                    } label: {
                        Text(item)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.8))
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.62), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: palette.accent.opacity(0.06), radius: 10, y: 5)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - 气泡

struct GlassBubble: View {
    let text: String
    let isUser: Bool
    let accent: Color
    var tts: Bool = true

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isUser { Spacer(minLength: 52) }
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(isUser ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background {
                    if isUser {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.black.opacity(0.85))
                    } else {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(.white.opacity(0.55), lineWidth: 1))
                    }
                }
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            if !isUser {
                if tts {
                    Button { Speaker.shared.speak(text) } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(6)
                    }
                }
                Spacer(minLength: 40)
            }
        }
    }
}

struct TypingBubble: View {
    var body: some View {
        HStack {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                HStack(spacing: 5) {
                    ForEach(0..<3) { i in
                        let v = 0.3 + 0.7 * max(0, sin(t * 4 - Double(i) * 0.6))
                        Circle().fill(.secondary).frame(width: 7, height: 7).opacity(v)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial))
            Spacer(minLength: 52)
        }
    }
}
