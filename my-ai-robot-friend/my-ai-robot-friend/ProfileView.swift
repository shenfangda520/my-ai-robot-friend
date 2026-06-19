//
//  ProfileView.swift
//  阿默 —— 资料页：身份、性格、状态、关系（全部可调）
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var store: ChatStore
    private var palette: MoodPalette { store.mood.palette }

    var body: some View {
        NavigationStack {
            RobotPage(palette: palette) {
                SiriCommunicationHero(
                    title: "和\(store.persona.name)校准频道",
                    subtitle: "像和 Siri 沟通一样，声波会持续呼吸；下面的设定会影响它听懂你之后怎么回应。",
                    chips: [store.mood.statusLabel, store.persona.relationship, store.intimacyLabel],
                    palette: palette
                )

                SurfaceSection(title: "身份", subtitle: "先定义它是谁，再定义它和你的关系。") {
                    LabeledField(label: "名字", text: $store.persona.name, placeholder: "阿默")
                    MenuPickerRow(label: "它是你的", selection: $store.persona.relationship,
                                  options: Persona.relationshipOptions)
                    LabeledField(label: "一句话身份", text: $store.persona.identity, placeholder: "住在你手机里的 AI 室友")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("背景故事").formFieldLabel()
                        TextField("它的来历、设定、说话习惯…", text: $store.persona.backstory, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.system(size: 15))
                            .glassFieldBackground()
                    }
                }

                SurfaceSection(title: "沟通方式", subtitle: "调整声波背后的性格参数。") {
                    DialRow(title: "毒舌 / 嘴硬", value: $store.persona.snark)
                    DialRow(title: "热情 / 黏人", value: $store.persona.warmth)
                    DialRow(title: "话痨程度", value: $store.persona.talkative)
                    DialRow(title: "幽默感", value: $store.persona.humor)
                    DialRow(title: "主动找你", value: $store.persona.proactiveness)
                }

                SurfaceSection(title: "当前状态", subtitle: "这些状态会随聊天慢慢变化。") {
                    MoodBar(title: "精力", value: store.mood.energy, color: palette.orb[1])
                    MoodBar(title: "信任", value: store.mood.trust, color: palette.orb[0])
                    MoodBar(title: "暴躁", value: store.mood.grumpiness, color: palette.accent)
                }

                SurfaceSection(title: "关系数据") {
                    InfoRow(label: "认识时长", value: "\(store.daysKnown) 天")
                    InfoRow(label: "亲密度", value: store.intimacyLabel)
                    InfoRow(label: "聊过的消息", value: "\(store.messages.count) 条")
                }
            }
            .navigationTitle(store.persona.name)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: store.persona) { _, _ in store.savePersona() }
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
                Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.black.opacity(0.62))
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.black.opacity(0.40))
            }
            Slider(value: Binding(get: { Double(value) },
                                  set: { value = Int($0) }),
                   in: 0...100, step: 1)
            .tint(Color.black.opacity(0.72))
        }
        .padding(12)
        .background(Color.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .animation(GenUIMotion.quick, value: value)
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.62))
            Spacer(minLength: 12)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.black.opacity(0.46))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.74), lineWidth: 1)
        )
    }
}

/// 行内式下拉行：外观和 LabeledField 的白框完全一致，标签左、当前值+箭头在右。
struct MenuPickerRow: View {
    let label: String
    @Binding var selection: String
    let options: [String]
    var placeholder: String = "未选择"
    var display: (String) -> String = { $0 }

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.62))
            Spacer(minLength: 12)
            Menu {
                Button(placeholder) { selection = "" }
                ForEach(options, id: \.self) { opt in
                    Button(display(opt)) { selection = opt }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selection.isEmpty ? placeholder : display(selection))
                        .font(.system(size: 15))
                        .foregroundStyle(Color.black.opacity(0.46))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.36))
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.74), lineWidth: 1)
        )
    }
}

struct MoodBar: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.black.opacity(0.62))
                Spacer()
                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.black.opacity(0.44))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.06))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.72), color.mixed(with: .white, by: 0.36)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .animation(GenUIMotion.quick, value: value)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.black.opacity(0.58))
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.black.opacity(0.40))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
    }
}

struct StatusChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.58))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.54), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.76), lineWidth: 1))
    }
}

extension Text {
    func formFieldLabel() -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.40))
    }
}

extension View {
    func formControlRow() -> some View {
        self
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .foregroundStyle(Color.black.opacity(0.62))
            .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.74), lineWidth: 1)
            )
    }
}
