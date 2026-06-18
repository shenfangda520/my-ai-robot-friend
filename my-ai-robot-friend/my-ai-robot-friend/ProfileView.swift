//
//  ProfileView.swift
//  阿默 —— 资料页：身份、性格、状态、关系（全部可调）
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var store: ChatStore
    @State private var avatarItem: PhotosPickerItem?
    private var palette: MoodPalette { store.mood.palette }

    var body: some View {
        NavigationStack {
            Form {
                // 头部：光球 + 名字 + 身份
                Section {
                    VStack(spacing: 10) {
                        AvatarView(imageData: store.avatarData, palette: palette, size: 130)
                        Text(store.persona.name)
                            .font(.title2.weight(.semibold))
                        Text(store.persona.identity)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text("此刻 · \(store.mood.statusLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)

                        HStack(spacing: 12) {
                            PhotosPicker(selection: $avatarItem, matching: .images) {
                                Label(store.avatarData == nil ? "设置头像" : "换头像",
                                      systemImage: "photo")
                                    .font(.footnote.weight(.medium))
                            }
                            if store.avatarData != nil {
                                Button {
                                    store.setAvatar(nil)
                                    avatarItem = nil
                                } label: {
                                    Label("用回光球", systemImage: "circle.dashed")
                                        .font(.footnote.weight(.medium))
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                // 性格
                Section("性格（影响它怎么跟你说话）") {
                    DialRow(title: "毒舌 / 嘴硬", value: $store.persona.snark)
                    DialRow(title: "热情 / 黏人", value: $store.persona.warmth)
                    DialRow(title: "话痨程度", value: $store.persona.talkative)
                    DialRow(title: "幽默感", value: $store.persona.humor)
                    DialRow(title: "主动性（找你的频率）", value: $store.persona.proactiveness)
                }
                .glassRow()

                // 身份
                Section("身份设定") {
                    LabeledField(label: "名字", text: $store.persona.name)
                    LabeledField(label: "一句话身份", text: $store.persona.identity)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("背景故事（可选）").font(.footnote).foregroundStyle(.secondary)
                        TextField("它的来历、设定…", text: $store.persona.backstory, axis: .vertical)
                            .lineLimit(2...5)
                    }
                }
                .glassRow()

                // 当前情绪
                Section("此刻的情绪") {
                    MoodBar(title: "精力", value: store.mood.energy, color: palette.orb[1])
                    MoodBar(title: "信任", value: store.mood.trust, color: palette.orb[0])
                    MoodBar(title: "暴躁", value: store.mood.grumpiness, color: palette.accent)
                }
                .glassRow()

                // 关系
                Section("你们的关系") {
                    InfoRow(label: "认识时长", value: "\(store.daysKnown) 天")
                    InfoRow(label: "亲密度", value: store.intimacyLabel)
                    InfoRow(label: "聊过的消息", value: "\(store.messages.count) 条")
                }
                .glassRow()
            }
            .glassForm(palette)
            .navigationTitle(store.persona.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onChange(of: store.persona) { _, _ in store.savePersona() }
            .onChange(of: avatarItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        store.setAvatar(data)
                    }
                }
            }
        }
    }
}

// MARK: - 小组件

struct DialRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(value)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: Binding(get: { Double(value) },
                                  set: { value = Int($0) }),
                   in: 0...100, step: 1)
            .tint(.primary)
        }
        .padding(.vertical, 2)
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct MoodBar: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(value)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 2)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
