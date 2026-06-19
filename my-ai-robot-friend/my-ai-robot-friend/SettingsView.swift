//
//  SettingsView.swift
//  阿默 —— 设置页：所有参数
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ChatStore
    var onClearHistory: () -> Void = {}

    @State private var keyDraft = ""
    @State private var confirmClearChat = false
    @State private var confirmClearMem = false
    @State private var showPromo = false

    private var palette: MoodPalette { store.mood.palette }

    var body: some View {
        NavigationStack {
            RobotPage(palette: palette) {
                GlassPageHeader(
                    systemImage: "gearshape.fill",
                    title: "设置",
                    subtitle: "管理模型连接、主动提醒、语音和数据。敏感内容只保存在本机。",
                    palette: palette
                )

                // 推广
                SurfaceSection(title: "推广", subtitle: "把\(store.persona.name)分享给更多人。") {
                    Button { showPromo = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .background(palette.accentSoft.opacity(0.6), in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                            Text("推广海报 · 分享")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.7))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.3))
                        }
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                }

                // 模型接入
                SurfaceSection(title: "模型接入", subtitle: "支持任意 OpenAI 兼容的模型。选预设会自动填好地址和模型名，也可改成自定义。") {
                    MenuPickerRow(label: "供应商", selection: $store.settings.providerName,
                                  options: ModelProvider.presets.map(\.name),
                                  placeholder: "选择")
                    LabeledField(label: "接口地址", text: $store.settings.apiBaseURL,
                                 placeholder: "https://…/v1")
                    LabeledField(label: "模型名", text: $store.settings.modelName,
                                 placeholder: "deepseek-chat")
                }

                // API Key
                SurfaceSection(title: "API Key", subtitle: "只存在本机。对应你上面选的供应商，去其官网创建并少量充值即可。") {
                    SecureField("sk-...", text: $keyDraft)
                        .font(.system(size: 15))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .glassFieldBackground()
                    Button {
                        store.saveApiKey(keyDraft)
                        hideKeyboard()
                    } label: {
                        HStack {
                            Text("保存 Key")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.black.opacity(0.34) : .white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.white.opacity(0.56) : Color.black.opacity(0.82), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.74), lineWidth: 1))
                        .shadow(color: .black.opacity(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.03 : 0.12), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    .scaleEffect(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.985 : 1)
                    .animation(GenUIMotion.quick, value: keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                // 主动找你
                SurfaceSection(title: "主动找你") {
                    Toggle("允许主动通知", isOn: $store.settings.notificationsEnabled)
                        .formControlRow()
                    if store.settings.notificationsEnabled {
                        RowDivider()
                        Toggle("深夜劝你睡觉", isOn: $store.settings.nightCheckIn)
                            .formControlRow()
                        RowDivider()
                        Toggle("早安问候", isOn: $store.settings.morningGreeting)
                            .formControlRow()
                    }
                }

                // 语音
                SurfaceSection(title: "语音") {
                    Toggle("显示朗读按钮", isOn: $store.settings.ttsEnabled)
                        .formControlRow()
                }

                // 气泡外观
                SurfaceSection(title: "气泡外观", subtitle: "自定义你发出的消息气泡颜色；不设则跟随它的心情变化。") {
                    ColorPicker(selection: Binding(
                        get: { store.settings.bubbleColor ?? palette.accentDeep },
                        set: { store.settings.bubbleHex = $0.hexString }
                    ), supportsOpacity: false) {
                        HStack(spacing: 12) {
                            Text("我的气泡颜色")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.62))
                        }
                    }
                    .formControlRow()
                    if !store.settings.bubbleHex.isEmpty {
                        RowDivider()
                        Button {
                            store.settings.bubbleHex = ""
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("跟随心情")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                            }
                            .foregroundStyle(Color.black.opacity(0.6))
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 高级
                SurfaceSection(title: "高级", subtitle: "创造力越高，回话越随机；越低则更稳。") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("创造力").font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.62))
                            Spacer()
                            Text(String(format: "%.1f", store.persona.creativity))
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundStyle(Color.black.opacity(0.40))
                        }
                        Slider(value: $store.persona.creativity, in: 0.5...1.6, step: 0.1)
                            .tint(Color.black.opacity(0.72))
                    }
                    .padding(.vertical, 8)
                    .animation(GenUIMotion.quick, value: store.persona.creativity)
                    RowDivider()
                    VStack(alignment: .leading, spacing: 7) {
                        Text("额外人设补充").formFieldLabel()
                        TextField("比如：说话喜欢用东北话、口头禅是…", text: $store.persona.customNote, axis: .vertical)
                            .lineLimit(2...5)
                            .font(.system(size: 15))
                            .glassFieldBackground()
                    }
                }

                // 关于我们
                SurfaceSection(title: "关于我们", subtitle: "这个 app 由 ShenFangda 设计和制作。") {
                    HStack(spacing: 14) {
                        MoonAvatarBadge(size: 74)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("阿默")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.72))
                            Text("月光头像已作为 app 形象展示，保留轻盈的 Siri 式动态沟通感。")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.black.opacity(0.42))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                    RowDivider()
                    AboutRow(label: "作者", value: "ShenFangda", systemImage: "person.crop.circle")
                    RowDivider()
                    Link(destination: URL(string: "https://github.com/shenfangda520/my-ai-robot-friend")!) {
                        HStack(spacing: 10) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.56), in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.72), lineWidth: 1))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("GitHub")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.black.opacity(0.68))
                                Text("github.com/shenfangda520/my-ai-robot-friend")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.black.opacity(0.38))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.34))
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    RowDivider()
                    AboutRow(label: "版本", value: "1.0", systemImage: "app.badge")
                }

                // 数据
                SurfaceSection(title: "数据") {
                    Button(role: .destructive) { confirmClearChat = true } label: {
                        DestructiveRowLabel(title: "清空聊天记录", systemImage: "trash")
                    }
                    .buttonStyle(.plain)
                    RowDivider()
                    Button(role: .destructive) { confirmClearMem = true } label: {
                        DestructiveRowLabel(title: "清空记忆", systemImage: "brain.head.profile")
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { keyDraft = store.apiKey }
            .onChange(of: store.settings) { _, _ in store.saveSettings() }
            .onChange(of: store.persona) { _, _ in store.savePersona() }
            .onChange(of: store.settings.providerName) { _, name in
                // 选了预设供应商，自动填地址和模型名（“自定义”则保留用户输入）
                if let p = ModelProvider.presets.first(where: { $0.name == name }), name != "自定义" {
                    store.settings.apiBaseURL = p.baseURL
                    store.settings.modelName = p.model
                }
            }
            .alert("清空聊天记录？", isPresented: $confirmClearChat) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    store.clearHistory()
                    onClearHistory()
                }
            } message: {
                Text("\(store.persona.name)会忘记和你聊过的一切，情绪也重置。记忆不受影响。")
            }
            .alert("清空记忆？", isPresented: $confirmClearMem) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) { store.clearMemories() }
            } message: {
                Text("\(store.persona.name)会忘记你让它记住的所有事。")
            }
            .sheet(isPresented: $showPromo) {
                PromotionView(store: store)
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct AboutRow: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.54))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.56), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.72), lineWidth: 1))
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.64))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.42))
        }
        .padding(.vertical, 8)
    }
}

private struct DestructiveRowLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(Color.red.opacity(0.08), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.72), lineWidth: 1))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Spacer()
        }
        .foregroundStyle(.red.opacity(0.72))
        .padding(.vertical, 8)
    }
}
