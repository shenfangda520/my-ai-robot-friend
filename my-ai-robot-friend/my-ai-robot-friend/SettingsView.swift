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
                // API Key
                Section {
                    SecureField("sk-...", text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("保存 Key") {
                        store.saveApiKey(keyDraft)
                        hideKeyboard()
                    }
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
                    if store.settings.notificationsEnabled {
                        Toggle("深夜劝你睡觉", isOn: $store.settings.nightCheckIn)
                        Toggle("早安问候", isOn: $store.settings.morningGreeting)
                    }
                }
                .glassRow()

                // 语音
                Section("语音") {
                    Toggle("显示朗读按钮", isOn: $store.settings.ttsEnabled)
                }
                .glassRow()

                // 高级
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("创造力").font(.subheadline)
                            Spacer()
                            Text(String(format: "%.1f", store.persona.creativity))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $store.persona.creativity, in: 0.5...1.6, step: 0.1)
                            .tint(.primary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("额外人设补充").font(.footnote).foregroundStyle(.secondary)
                        TextField("比如：说话喜欢用东北话、口头禅是…", text: $store.persona.customNote, axis: .vertical)
                            .lineLimit(2...5)
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
                    }
                    Button(role: .destructive) { confirmClearMem = true } label: {
                        Label("清空记忆", systemImage: "brain.head.profile")
                    }
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
