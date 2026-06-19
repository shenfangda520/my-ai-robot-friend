//
//  ContentView.swift
//  阿默 —— 聊天页（全息玻璃）
//

import SwiftUI
import UIKit

struct ChatView: View {
    @ObservedObject var store: ChatStore
    @StateObject private var voiceInput = VoiceInputController()
    @State private var input = ""
    @State private var memoryDraft = ""
    @State private var showingMemoryComposer = false
    @State private var toast: String?
    @FocusState private var inputFocused: Bool

    private var palette: MoodPalette { store.mood.palette }
    private var isHero: Bool { store.messages.count <= 1 }
    private var isComposing: Bool { inputFocused || !input.isEmpty }
    private var isPreChatHome: Bool {
        isHero && !isComposing && !voiceInput.isListening && !showingMemoryComposer
    }

    var body: some View {
        ZStack {
            GenUISearchBackground(palette: palette)
            VStack(spacing: 0) {
                header
                if isHero {
                    heroHome
                } else {
                    // 顶部胶囊已显示头像+名字+状态，这里不再重复 orbHeader
                    messageList
                }
                if !isPreChatHome {
                    inputBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .toolbar(isPreChatHome ? .hidden : .visible, for: .tabBar)
        .animation(GenUIMotion.morph, value: isHero)
        .animation(GenUIMotion.morph, value: isComposing)
        .animation(GenUIMotion.morph, value: isPreChatHome)
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.82), in: Capsule())
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(GenUIMotion.quick, value: toast)
        .onChange(of: voiceInput.transcript) { _, value in
            input = value
        }
        .onDisappear {
            voiceInput.stop()
        }
    }

    private func flash(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            await MainActor.run { toast = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(GenUIMotion.quick) {
                    inputFocused = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isComposing ? "xmark" : "sun.max.fill")
                        .font(.system(size: 12, weight: .semibold))
                    if !isComposing {
                        Text("28°")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundStyle(Color.black.opacity(0.58))
                .frame(width: isComposing ? 34 : 58, height: 34)
                .background(.white.opacity(0.62), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Button { } label: {
                HStack(spacing: 8) {
                    SiriWaveView(palette: palette)
                        .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.persona.name)
                            .font(.system(size: 12, weight: .semibold))
                        Text(store.isSending ? "生成中" : store.mood.statusLabel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.38))
                    }
                }
                .foregroundStyle(Color.black.opacity(0.62))
                .padding(.leading, 8)
                .padding(.trailing, 12)
                .frame(height: 38)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.78), lineWidth: 1))
                .shadow(color: .black.opacity(0.055), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var orbHeader: some View {
        HStack(spacing: 10) {
            SiriWaveView(palette: palette)
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.isSending ? "\(store.persona.name)正在生成" : store.persona.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.66))
                Text(store.isSending ? "正在组织回应" : store.mood.statusLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.black.opacity(0.40))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.72), lineWidth: 1))
        .shadow(color: .black.opacity(0.055), radius: 14, y: 7)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var heroHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroGreeting

                AdaptiveStatusPanel(
                    palette: palette,
                    name: store.persona.name,
                    moodLabel: store.mood.statusLabel,
                    intimacyLabel: store.intimacyLabel,
                    prompt: input,
                    mode: store.isSending ? .thinking : (isComposing ? .composing : .ready)
                )
                .frame(minHeight: isComposing ? 172 : 232)
                .frame(maxWidth: .infinity)
                .padding(.top, isComposing ? 12 : 4)
                .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .onTapGesture {
                    if isPreChatHome { revealInput() }
                }

                if !isComposing {
                    DailyBriefCard(store: store, palette: palette, submit: sendPreset)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if !isComposing {
                    SuggestionRail(items: suggestions, palette: palette, action: sendPreset)
                        .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, isComposing ? 28 : 10)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
    }

    private var heroGreeting: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(dateLine)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.42))
            Text("\(greeting)，\n\(displayName)")
                .font(.system(size: isComposing ? 24 : 32, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.72))
                .lineSpacing(2)
                .contentTransition(.opacity)
            Text(store.isSending ? "\(store.persona.name)正在想。" : "\(store.persona.name) · \(store.mood.statusLabel)")
                .font(.system(size: 14))
                .foregroundStyle(Color.black.opacity(0.42))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(isHero ? [] : store.messages) { m in
                        GlassBubble(text: m.content, isUser: m.isUser,
                                    accent: palette.accent, palette: palette,
                                    tts: store.settings.ttsEnabled,
                                    userBubbleColor: store.settings.bubbleColor,
                                    onRemember: {
                                        store.addMemory(m.content)
                                        flash("已记住 ✓")
                                    },
                                    onAddEvent: {
                                        store.addEvent(m.content, date: Date())
                                        flash("已加入事迹 ✓")
                                    })
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
        VStack(spacing: 10) {
            if voiceInput.isListening {
                HStack(spacing: 8) {
                    SiriWaveView(palette: palette)
                        .frame(width: 28, height: 28)
                    Text("正在听你说…")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.54))
                    Spacer()
                    Button("停止") {
                        voiceInput.stop()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.54))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.54), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.76), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if showingMemoryComposer {
                memoryComposer
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if isComposing {
                SuggestionRail(items: suggestions, palette: palette, action: sendPreset)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(spacing: 9) {
                Button {
                    withAnimation(GenUIMotion.quick) {
                        showingMemoryComposer.toggle()
                        inputFocused = false
                        voiceInput.stop()
                    }
                } label: {
                    Image(systemName: showingMemoryComposer ? "xmark" : "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.46))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.54), in: Circle())
                }
                .buttonStyle(.plain)

            TextField("跟\(store.persona.name)说点什么…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 16))
                .focused($inputFocused)
                .onSubmit(submit)

            Button(action: inputButtonTapped) {
                Image(systemName: inputButtonIcon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(canSend || voiceInput.isListening ? .white : Color.black.opacity(0.44))
                    .frame(width: 34, height: 34)
                    .background {
                        Circle()
                            .fill(canSend ? Color.black.opacity(0.82) : (voiceInput.isListening ? palette.accent.opacity(0.82) : Color.white.opacity(0.54)))
                    }
            }
            .disabled(store.isSending)
            .scaleEffect(canSend || voiceInput.isListening ? 1.0 : 0.96)
            .animation(GenUIMotion.quick, value: canSend)
            .animation(GenUIMotion.quick, value: voiceInput.isListening)
            }
            .padding(8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(isComposing ? 0.88 : 0.66), lineWidth: 1))
            .shadow(color: .black.opacity(isComposing ? 0.12 : 0.07), radius: isComposing ? 22 : 14, y: 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var memoryComposer: some View {
        HStack(spacing: 9) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.48))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.54), in: Circle())

            TextField("要\(store.persona.name)记住什么…", text: $memoryDraft, axis: .vertical)
                .lineLimit(1...3)
                .font(.system(size: 14))

            Button {
                saveMemoryFromChat()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(canSaveMemory ? .white : Color.black.opacity(0.28))
                    .frame(width: 30, height: 30)
                    .background(canSaveMemory ? Color.black.opacity(0.80) : Color.white.opacity(0.50), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSaveMemory)
        }
        .padding(8)
        .background(Color.white.opacity(0.58), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.78), lineWidth: 1))
        .shadow(color: .black.opacity(0.055), radius: 12, y: 6)
    }

    private var canSend: Bool {
        !store.isSending && !input.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var canSaveMemory: Bool {
        !memoryDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var inputButtonIcon: String {
        if canSend { return "arrow.up" }
        return voiceInput.isListening ? "waveform" : "mic.fill"
    }

    private func revealInput() {
        withAnimation(GenUIMotion.morph) {
            inputFocused = true
        }
    }

    private func inputButtonTapped() {
        if canSend {
            submit()
        } else {
            inputFocused = false
            voiceInput.toggle(baseText: input)
        }
    }

    private func submit() {
        guard canSend else { return }
        voiceInput.stop()
        let text = input
        withAnimation(GenUIMotion.quick) {
            input = ""
            inputFocused = false
        }
        Task { await store.send(text) }
    }

    private func sendPreset(_ text: String) {
        voiceInput.stop()
        withAnimation(GenUIMotion.quick) {
            input = ""
            inputFocused = false
        }
        Task { await store.send(text) }
    }

    private func saveMemoryFromChat() {
        let text = memoryDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.addMemory(text)
        withAnimation(GenUIMotion.quick) {
            memoryDraft = ""
            showingMemoryComposer = false
        }
    }

    private var displayName: String {
        let preferred = store.persona.userNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !preferred.isEmpty { return preferred }
        let userName = store.user.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !userName.isEmpty { return userName }
        return "我在"
    }

    private var suggestions: [String] {
        // 有动态推测的就用动态的；否则(空首页/还没生成)用固定开场建议
        store.suggestions.isEmpty ? defaultSuggestions : store.suggestions
    }

    private var defaultSuggestions: [String] {
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

private struct GenUISearchBackground: View {
    let palette: MoodPalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xF5F7F8),
                    Color(hex: 0xEEF2F3),
                    Color(hex: 0xF8F8F6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                Circle()
                    .fill(palette.orb[0].opacity(0.20))
                    .frame(width: w * 0.72, height: w * 0.72)
                    .blur(radius: 50)
                    .offset(x: w * 0.36, y: h * 0.10)

                Circle()
                    .fill(Color(hex: 0xF5D3B7).opacity(0.26))
                    .frame(width: w * 0.68, height: w * 0.68)
                    .blur(radius: 54)
                    .offset(x: w * 0.05, y: h * 0.22)

                Circle()
                    .fill(Color(hex: 0xB9D7F6).opacity(0.18))
                    .frame(width: w * 0.78, height: w * 0.78)
                    .blur(radius: 64)
                    .offset(x: -w * 0.30, y: h * 0.54)
            }
            .ignoresSafeArea()

            Color.white.opacity(0.42).ignoresSafeArea()
        }
    }
}

private enum AdaptivePanelMode: Equatable {
    case ready
    case composing
    case thinking
}

private struct AdaptiveStatusPanel: View {
    let palette: MoodPalette
    let name: String
    let moodLabel: String
    let intimacyLabel: String
    let prompt: String
    let mode: AdaptivePanelMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatusGlyph(palette: palette, mode: mode)
                    .frame(width: mode == .ready ? 42 : 34, height: mode == .ready ? 42 : 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(statusTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.62))
                    Text(statusCaption)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.black.opacity(0.38))
                        .lineLimit(1)
                }

                Spacer()

                Text(modeBadge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.50))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.56), in: Capsule())
            }

            if mode == .ready {
                HomeVoicePortal(name: name, moodLabel: moodLabel, palette: palette)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(primaryLine)
                        .font(.system(size: 25, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.72))
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)
                        .contentTransition(.opacity)

                    Text(secondaryLine)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.black.opacity(0.42))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            bottomContent
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: mode == .ready ? 34 : 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: mode == .ready ? 34 : 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.70),
                                    Color(hex: 0xF5D9C5).opacity(mode == .thinking ? 0.34 : 0.22),
                                    palette.accentSoft.opacity(mode == .thinking ? 0.34 : 0.18),
                                    Color.white.opacity(0.40)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: mode == .ready ? 34 : 28, style: .continuous)
                .stroke(.white.opacity(mode == .composing ? 0.86 : 0.68), lineWidth: 1)
        )
        .shadow(color: .black.opacity(mode == .ready ? 0.09 : 0.07), radius: mode == .ready ? 24 : 16, y: 10)
        .animation(GenUIMotion.morph, value: mode)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var bottomContent: some View {
        switch mode {
        case .ready:
            HStack(spacing: 8) {
                ContextChip(title: moodLabel, icon: "waveform.path", palette: palette)
                ContextChip(title: intimacyLabel, icon: "heart", palette: palette)
                ContextChip(title: "Ask", icon: "sparkle", palette: palette)
            }
        case .composing:
            HStack(spacing: 8) {
                Image(systemName: "text.cursor")
                    .font(.system(size: 13, weight: .semibold))
                Text(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "等你开口" : "正在整理问题")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Image(systemName: "return")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(palette.accentDeep.opacity(0.72))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.36))
            }
        case .thinking:
            ProgressView()
                .progressViewStyle(.linear)
                .tint(palette.accentDeep.opacity(0.75))
                .padding(.vertical, 8)
        }
    }

    private var statusTitle: String {
        switch mode {
        case .ready: return "为此刻生成"
        case .composing: return "正在适配输入"
        case .thinking: return "\(name)正在思考"
        }
    }

    private var statusCaption: String {
        switch mode {
        case .ready: return "现在适合慢慢聊"
        case .composing: return "先把问题放下来"
        case .thinking: return "正在组织更像你的回答"
        }
    }

    private var modeBadge: String {
        switch mode {
        case .ready: return "READY"
        case .composing: return "FOCUS"
        case .thinking: return "LIVE"
        }
    }

    private var primaryLine: String {
        switch mode {
        case .ready: return "\(name)在这儿。"
        case .composing: return prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "想问什么？" : "我听着。"
        case .thinking: return "正在生成回应。"
        }
    }

    private var secondaryLine: String {
        switch mode {
        case .ready: return "\(moodLabel)，可以聊天、复盘，或者把一件事讲清楚。"
        case .composing: return "不用想清楚再说，先从一个词开始也行。"
        case .thinking: return "保留语气，也尽量把答案说得有用。"
        }
    }
}

private struct HomeVoicePortal: View {
    let name: String
    let moodLabel: String
    let palette: MoodPalette

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(palette.accentSoft.opacity(0.42))
                    .frame(width: 92, height: 92)
                    .blur(radius: 18)
                SiriWaveView(palette: palette)
                    .frame(width: 82, height: 82)
                    .background(Color.white.opacity(0.32), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.82), lineWidth: 1))
                    .shadow(color: palette.accent.opacity(0.14), radius: 18, y: 8)
            }
            .frame(width: 96, height: 96)

            VStack(alignment: .leading, spacing: 8) {
                Text("\(name)待命中")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("\(moodLabel)。可以直接打字，也可以点麦克风说。")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.42))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    Label("Voice", systemImage: "waveform")
                    Label("Memory", systemImage: "brain.head.profile")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.48))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.36), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct StatusGlyph: View {
    let palette: MoodPalette
    let mode: AdaptivePanelMode

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let pulse = mode == .thinking ? 1 + 0.08 * sin(t * 3.0) : 1

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.accentSoft.opacity(0.88))
                Circle()
                    .fill(palette.orb[0].opacity(0.88))
                    .frame(width: 18, height: 18)
                    .offset(x: mode == .composing ? -5 : -8, y: mode == .thinking ? -7 : -3)
                Circle()
                    .fill(palette.orb[2].opacity(0.78))
                    .frame(width: 16, height: 16)
                    .offset(x: mode == .composing ? 7 : 8, y: mode == .thinking ? 7 : 6)
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            }
            .scaleEffect(pulse)
        }
    }

    private var symbol: String {
        switch mode {
        case .ready: return "sparkles"
        case .composing: return "text.alignleft"
        case .thinking: return "wand.and.stars"
        }
    }
}

private struct ContextChip: View {
    let title: String
    let icon: String
    let palette: MoodPalette

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(palette.accentDeep.opacity(0.74))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.34), in: Capsule())
    }
}

private struct DailyBriefCard: View {
    @ObservedObject var store: ChatStore
    let palette: MoodPalette
    let submit: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.36))
                    Text("AI Companion")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.68))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.48))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.58), in: Circle())
            }

            Text(openingLine)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.52))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("22:30")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.70))
                    Text("check in")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.34))
                }

                RouteLine(color: palette.accent)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("06:20")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.70))
                    Text(store.mood.statusLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.34))
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 2)

            Button {
                submit("用你现在的状态，帮我规划一下今天。")
            } label: {
                HStack {
                    Text("Book now")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                        .background(Color.black.opacity(0.08), in: Circle())
                }
                .foregroundStyle(Color.black.opacity(0.70))
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .background(.white.opacity(0.64), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.72), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                        .fill(Color.white.opacity(0.44))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.075), radius: 18, y: 9)
        .revealOnAppear(delay: 0.04)
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

private struct RouteLine: View {
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.black.opacity(0.24))
                .frame(width: 5, height: 5)
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
                .overlay(alignment: .center) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(color.opacity(0.72), in: Circle())
                        .shadow(color: color.opacity(0.22), radius: 8, y: 4)
                }
            Circle()
                .fill(Color.black.opacity(0.24))
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MetricRow: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color.mixed(with: .black, by: 0.22))
                .frame(width: 24, height: 24)
                .background(color.opacity(0.16), in: Circle())

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Capsule()
                .fill(Color.black.opacity(0.07))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.74))
                        .frame(width: max(12, CGFloat(value) * 1.45), height: 5)
                        .contentTransition(.numericText())
                }

            Text("\(value)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color.mixed(with: .black, by: 0.30).opacity(0.85))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.24), in: RoundedRectangle(cornerRadius: Glass.Radius.row, style: .continuous))
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
                            .foregroundStyle(palette.accentDeep.opacity(0.82))
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Glass.stroke, lineWidth: Glass.lineWidth))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: palette.accent.opacity(0.07), radius: 8, y: 4)
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
    let palette: MoodPalette
    var tts: Bool = true
    var userBubbleColor: Color? = nil
    var onRemember: (() -> Void)? = nil
    var onAddEvent: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isUser { Spacer(minLength: 52) }
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(isUser ? .white : palette.accentDeep)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background {
                    if isUser {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(userBubbleColor ?? palette.accentDeep.opacity(0.92))
                    } else {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Glass.stroke, lineWidth: Glass.lineWidth))
                    }
                }
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                .contextMenu {
                    Button { UIPasteboard.general.string = text } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                    if let onRemember {
                        Button { onRemember() } label: {
                            Label("让它记住这句", systemImage: "brain.head.profile")
                        }
                    }
                    if let onAddEvent {
                        Button { onAddEvent() } label: {
                            Label("加入事迹", systemImage: "calendar.badge.plus")
                        }
                    }
                }
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
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Glass.stroke, lineWidth: Glass.lineWidth))
            Spacer(minLength: 52)
        }
    }
}
