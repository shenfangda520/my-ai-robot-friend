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
                    HStack(spacing: 8) {
                        TextField("让\(store.persona.name)记住一件事…", text: $draft, axis: .vertical)
                            .lineLimit(1...3)
                            .focused($focused)
                        Button {
                            store.addMemory(draft)
                            draft = ""
                            focused = false
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.primary)
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
                }

                // 事迹时间线
                Section {
                    DatePicker("日期", selection: $eventDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    HStack(spacing: 8) {
                        TextField("发生了什么…", text: $eventDraft, axis: .vertical)
                            .lineLimit(1...3)
                        Button {
                            store.addEvent(eventDraft, date: eventDate)
                            eventDraft = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.primary)
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
                        }
                        .onDelete { store.deleteEvent(at: $0) }
                    }
                    .glassRow()
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
