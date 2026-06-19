//
//  MemoryView.swift
//  阿默 —— 记忆页：它记得关于你的事（会影响它怎么说话）
//

import SwiftUI

struct MemoryView: View {
    @ObservedObject var store: ChatStore
    @State private var draft = ""
    @State private var eventDraft = ""
    @State private var eventDate = Date()
    @FocusState private var focused: Bool

    private var palette: MoodPalette { store.mood.palette }

    private var eventDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f
    }

    var body: some View {
        NavigationStack {
            RobotPage(palette: palette) {
                GlassPageHeader(
                    imageName: "MemoryEmptyIcon",
                    title: "记忆库",
                    subtitle: "把你和阿默之间重要的设定、小事和日期放在这里。",
                    palette: palette
                )

                SurfaceSection(title: "添加记忆", subtitle: "关于你和你们相处的事，会在聊天里自然用上。") {
                    HStack(alignment: .bottom, spacing: 10) {
                        TextField("让\(store.persona.name)记住一件事…", text: $draft, axis: .vertical)
                            .lineLimit(1...3)
                            .focused($focused)
                            .font(.system(size: 15))
                            .glassFieldBackground()
                        Button {
                            store.addMemory(draft)
                            draft = ""
                            focused = false
                        } label: {
                            Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.black.opacity(0.28) : Color.black.opacity(0.72))
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.58), in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.74), lineWidth: 1))
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                        .scaleEffect(draft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.96 : 1)
                        .animation(GenUIMotion.quick, value: draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if !store.memories.isEmpty {
                    SurfaceSection(title: "它记得的事", subtitle: "\(store.memories.count) 条") {
                        ForEach(Array(store.memories.enumerated()), id: \.element.id) { index, memory in
                            HStack(alignment: .top, spacing: 10) {
                                Text(memory.text)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.black.opacity(0.64))
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                Button(role: .destructive) {
                                    store.deleteMemory(at: IndexSet(integer: index))
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(Color.black.opacity(0.36))
                            }
                            .padding(.vertical, 7)
                            if index != store.memories.count - 1 {
                                RowDivider()
                            }
                        }
                    }
                } else {
                    MemoryEmptyCard(
                        imageName: "MemoryEmptyIcon",
                        title: "还没有记忆",
                        subtitle: "写下一件关于你、关于你们的事，\(store.persona.name)以后聊天时会自然想起来。",
                        palette: palette
                    )
                }

                // 事迹时间线
                SurfaceSection(title: "你们的事迹", subtitle: "把共同经历过的小事放进时间线。") {
                    DatePicker("日期", selection: $eventDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .formControlRow()
                    RowDivider()
                    HStack(alignment: .bottom, spacing: 10) {
                        TextField("发生了什么…", text: $eventDraft, axis: .vertical)
                            .lineLimit(1...3)
                            .font(.system(size: 15))
                            .glassFieldBackground()
                        Button {
                            store.addEvent(eventDraft, date: eventDate)
                            eventDraft = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(eventDraft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.black.opacity(0.28) : Color.black.opacity(0.72))
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.58), in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.74), lineWidth: 1))
                        }
                        .disabled(eventDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                        .scaleEffect(eventDraft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.96 : 1)
                        .animation(GenUIMotion.quick, value: eventDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if !store.events.isEmpty {
                    SurfaceSection(title: "一起经历过的", subtitle: "\(store.events.count) 条") {
                        ForEach(Array(store.events.enumerated()), id: \.element.id) { index, event in
                            HStack(alignment: .top, spacing: 10) {
                                Text(eventDateFormatter.string(from: event.date))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Color.black.opacity(0.38))
                                    .frame(width: 56, alignment: .leading)
                                Text(event.text)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.black.opacity(0.64))
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                Button(role: .destructive) {
                                    store.deleteEvent(at: IndexSet(integer: index))
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(Color.black.opacity(0.36))
                            }
                            .padding(.vertical, 5)
                            if index != store.events.count - 1 {
                                RowDivider()
                            }
                        }
                    }
                } else {
                    MemoryEmptyCard(
                        imageName: "EventEmptyIcon",
                        title: "还没有共同经历",
                        subtitle: "把重要日子和小事记下来，它会慢慢长出属于你们的时间线。",
                        palette: palette
                    )
                }
            }
            .navigationTitle("记忆")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct MemoryEmptyCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let palette: MoodPalette

    var body: some View {
        HStack(spacing: 14) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.66))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.black.opacity(0.40))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                        .fill(Color.white.opacity(0.46))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.055), radius: 16, y: 8)
        .revealOnAppear(delay: 0.04)
    }
}
