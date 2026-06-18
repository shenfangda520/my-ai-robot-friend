//
//  SettingsView.swift
//  阿默 —— 设置页：所有参数
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ChatStore

    @State private var keyDraft = ""
    @State private var confirmClearChat = false
    @State private var confirmClearMem = false

    private var palette: MoodPalette { store.mood.palette }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    GlassPageHeader(
                        systemImage: "gearshape.fill",
                        title: "设置",
                        subtitle: "管理模型连接、主动提醒、语音和数据。敏感内容只保存在本机。",
                        palette: palette
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))

                // API Key
                Section {
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
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.25 : 0.86), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("DeepSeek API Key")
                } footer: {
                    Text("去 platform.deepseek.com 创建，充几块就能用很久。只存在本机。")
                }
                .glassRow()

                // 主动找你
                Section("主动找你") {
                    Toggle("允许主动通知", isOn: $store.settings.notificationsEnabled)
                        .formControlRow()
                    if store.settings.notificationsEnabled {
                        Toggle("深夜劝你睡觉", isOn: $store.settings.nightCheckIn)
                            .formControlRow()
                        Toggle("早安问候", isOn: $store.settings.morningGreeting)
                            .formControlRow()
                    }
                }
                .glassRow()

                // 语音
                Section("语音") {
                    Toggle("显示朗读按钮", isOn: $store.settings.ttsEnabled)
                        .formControlRow()
                }
                .glassRow()

                // 高级
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("创造力").font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(String(format: "%.1f", store.persona.creativity))
                                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $store.persona.creativity, in: 0.5...1.6, step: 0.1)
                            .tint(.primary)
                    }
                    .padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("额外人设补充").formFieldLabel()
                        TextField("比如：说话喜欢用东北话、口头禅是…", text: $store.persona.customNote, axis: .vertical)
                            .lineLimit(2...5)
                            .font(.system(size: 15))
                            .glassFieldBackground()
                    }
                } header: {
                    Text("高级")
                } footer: {
                    Text("创造力越高，回话越随机、越天马行空；低则更稳。")
                }
                .glassRow()

                // 数据
                Section("数据") {
                    Button(role: .destructive) { confirmClearChat = true } label: {
                        Label("清空聊天记录", systemImage: "trash")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.vertical, 7)
                    Button(role: .destructive) { confirmClearMem = true } label: {
                        Label("清空记忆", systemImage: "brain.head.profile")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.vertical, 7)
                }
                .glassRow()
            }
            .glassForm(palette)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear { keyDraft = store.apiKey }
            .onChange(of: store.settings) { _, _ in store.saveSettings() }
            .onChange(of: store.persona) { _, _ in store.savePersona() }
            .alert("清空聊天记录？", isPresented: $confirmClearChat) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) { store.clearHistory() }
            } message: {
                Text("\(store.persona.name)会忘记和你聊过的一切，情绪也重置。记忆不受影响。")
            }
            .alert("清空记忆？", isPresented: $confirmClearMem) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) { store.clearMemories() }
            } message: {
                Text("\(store.persona.name)会忘记你让它记住的所有事。")
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
