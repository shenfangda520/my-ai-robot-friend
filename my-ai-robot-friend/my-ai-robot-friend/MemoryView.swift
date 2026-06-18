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
            Form {
                Section {
                    GlassPageHeader(
                        imageName: "MemoryEmptyIcon",
                        title: "记忆库",
                        subtitle: "把你和阿默之间重要的设定、小事和日期放在这里。",
                        palette: palette
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))

                Section {
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
                                .foregroundStyle(draft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.45) : Color.primary)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.38), in: Circle())
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("添加记忆")
                } footer: {
                    Text("这些是\(store.persona.name)记得的、关于你和你们相处的事。比如「我是程序员」「我怕狗」「我们约好周末看电影」。它会在聊天里用上。")
                }
                .glassRow()

                if !store.memories.isEmpty {
                    Section("它记得的事（\(store.memories.count)）") {
                        ForEach(store.memories) { m in
                            Text(m.text).font(.subheadline)
                        }
                        .onDelete { store.deleteMemory(at: $0) }
                    }
                    .glassRow()
                } else {
                    Section {
                        MemoryEmptyCard(
                            imageName: "MemoryEmptyIcon",
                            title: "还没有记忆",
                            subtitle: "写下一件关于你、关于你们的事，\(store.persona.name)以后聊天时会自然想起来。"
                        )
                    }
                    .listRowBackground(Color.clear)
                }

                // 事迹时间线
                Section {
                    DatePicker("日期", selection: $eventDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .formControlRow()
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
                                .foregroundStyle(eventDraft.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.45) : Color.primary)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.38), in: Circle())
                        }
                        .disabled(eventDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("你们的事迹")
                } footer: {
                    Text("一起经历过的事，比如「一起熬夜看球」「陪你搬家」。\(store.persona.name)会记着，聊天时自然提起。")
                }
                .glassRow()

                if !store.events.isEmpty {
                    Section("一起经历过的（\(store.events.count)）") {
                        ForEach(store.events) { e in
                            HStack(alignment: .top, spacing: 10) {
                                Text(eventDateFormatter.string(from: e.date))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 56, alignment: .leading)
                                Text(e.text).font(.subheadline)
                            }
                            .padding(.vertical, 5)
                        }
                        .onDelete { store.deleteEvent(at: $0) }
                    }
                    .glassRow()
                } else {
                    Section {
                        MemoryEmptyCard(
                            imageName: "EventEmptyIcon",
                            title: "还没有共同经历",
                            subtitle: "把重要日子和小事记下来，它会慢慢长出属于你们的时间线。"
                        )
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .glassForm(palette)
            .navigationTitle("记忆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                if !store.memories.isEmpty { EditButton() }
            }
        }
    }
}

private struct MemoryEmptyCard: View {
    let imageName: String
    let title: String
    let subtitle: String

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
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.58), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
    }
}
