//
//  ProfileView.swift
//  阿默 —— 资料页：身份、性格、状态、关系（全部可调）
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var store: ChatStore
    private var palette: MoodPalette { store.mood.palette }

    var body: some View {
        NavigationStack {
            Form {
                // 头部：当前形象 + 名字 + 身份
                Section {
                    HStack(spacing: 16) {
                        AvatarView(imageData: store.currentAvatarData, palette: palette, size: 112)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(store.persona.name)
                                .font(.system(size: 25, weight: .semibold))
                            Text(store.persona.identity)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 8) {
                                StatusChip(text: store.mood.statusLabel, color: palette.accent)
                                StatusChip(text: store.mood.expression.label, color: palette.orb[1])
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(.white.opacity(0.64), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 22, y: 12)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))

                // 多套表情头像
                Section {
                    HStack(spacing: 14) {
                        ForEach(AvatarExpression.allCases, id: \.self) { e in
                            ExpressionSlot(store: store, expression: e)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                } header: {
                    Text("头像（不同心情显示不同表情）")
                } footer: {
                    Text("给「开心 / 生气 / 困 / 默认」各设一张图，\(store.persona.name)会按当前心情自动切换。长按某张可清除。只设「默认」就所有心情都用它；都不设就用情绪光球。")
                }
                .glassRow()

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
                    Picker("它是你的", selection: $store.persona.relationship) {
                        ForEach(Persona.relationshipOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .formControlRow()
                    LabeledField(label: "一句话身份", text: $store.persona.identity)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("背景故事（可选）").formFieldLabel()
                        TextField("它的来历、设定…", text: $store.persona.backstory, axis: .vertical)
                            .lineLimit(2...5)
                            .glassFieldBackground()
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
        }
    }
}

/// 单个表情头像槽：点选图片、长按清除。
@MainActor
struct ExpressionSlot: View {
    @ObservedObject var store: ChatStore
    let expression: AvatarExpression
    @State private var item: PhotosPickerItem?

    var body: some View {
        let current = store.mood.expression == expression
        let avatarData = store.avatarImages[expression.rawValue]

        VStack(spacing: 6) {
            PhotosPicker(selection: $item, matching: .images) {
                ZStack {
                    if let data = avatarData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                    } else {
                        Image(expression.assetName)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 60, height: 60)
                .background(.white.opacity(0.18))
                .clipShape(Circle())
                .overlay(Circle().stroke(current ? Color.primary.opacity(0.72) : .white.opacity(0.6), lineWidth: current ? 2 : 1))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            Text(expression.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(7)
        .background(current ? Color.white.opacity(0.42) : Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contextMenu {
            if store.avatar(for: expression) != nil {
                Button(role: .destructive) {
                    store.setAvatar(nil, for: expression)
                } label: { Label("清除这张", systemImage: "trash") }
            }
        }
        .onChange(of: item) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    store.setAvatar(data, for: expression)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding(get: { Double(value) },
                                  set: { value = Int($0) }),
                   in: 0...100, step: 1)
            .tint(.primary)
        }
        .padding(.vertical, 8)
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 9)
    }
}

struct MoodBar: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 7)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium))
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
    }
}

struct StatusChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary.opacity(0.78))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.54), lineWidth: 1))
    }
}

extension Text {
    func formFieldLabel() -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

extension View {
    func formControlRow() -> some View {
        self
            .padding(.vertical, 8)
    }
}
