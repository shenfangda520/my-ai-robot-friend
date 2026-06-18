//
//  ChatStore.swift
//  阿默的大脑：状态、人设、记忆、设置、收发消息
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ChatStore: ObservableObject {
    @Published var messages: [Message] = []
    @Published var mood = Mood()
    @Published var isSending = false
    @Published var apiKey = ""
    @Published var persona = Persona()
    @Published var settings = AppSettings()
    @Published var memories: [MemoryFact] = []
    @Published var user = UserProfile()
    @Published var events: [SharedEvent] = []
    @Published var avatarData: Data?   // 自定义头像图片；nil = 用默认情绪光球
    @Published var firstMet = Date()

    private let kMessages = "chat_history"
    private let kMood = "mood"
    private let kApiKey = "deepseek_api_key"
    private let kLastSeen = "last_seen"
    private let kPersona = "persona"
    private let kSettings = "settings"
    private let kMemories = "memories"
    private let kUser = "user_profile"
    private let kEvents = "shared_events"
    private let kAvatar = "avatar_image"
    private let kFirstMet = "first_met"

    init() { load() }

    // MARK: - 读写

    private func decode<T: Decodable>(_ t: T.Type, _ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(t, from: data)
    }
    private func encodeSet<T: Encodable>(_ v: T, _ key: String) {
        if let data = try? JSONEncoder().encode(v) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        let d = UserDefaults.standard
        apiKey = d.string(forKey: kApiKey) ?? ""
        if let v = decode([Message].self, kMessages) { messages = v }
        if let v = decode(Mood.self, kMood) { mood = v }
        if let v = decode(Persona.self, kPersona) { persona = v }
        if let v = decode(AppSettings.self, kSettings) { settings = v }
        if let v = decode([MemoryFact].self, kMemories) { memories = v }
        if let v = decode(UserProfile.self, kUser) { user = v }
        if let v = decode([SharedEvent].self, kEvents) { events = v }
        avatarData = d.data(forKey: kAvatar)
        if let fm = d.object(forKey: kFirstMet) as? Date { firstMet = fm }
        else { d.set(firstMet, forKey: kFirstMet) }

        var openerAppended = false
        if let last = d.object(forKey: kLastSeen) as? Date {
            mood.decay(since: last)
            let gapHours = Int(Date().timeIntervalSince(last) / 3600)
            if !messages.isEmpty, let opener = proactiveOpener(gapHours: gapHours) {
                messages.append(Message(role: .assistant, content: opener, time: Date()))
                openerAppended = true
            }
        }

        if messages.isEmpty {
            messages.append(Message(
                role: .assistant,
                content: "哦，新室友？我是\(persona.name)。先去「设置」里把 API Key 填上，不然我没法跟你废话。",
                time: Date()))
        }
        if openerAppended { persist() }
    }

    private func persist() {
        encodeSet(messages, kMessages)
        encodeSet(mood, kMood)
        UserDefaults.standard.set(Date(), forKey: kLastSeen)
    }

    func savePersona() { encodeSet(persona, kPersona) }

    func saveSettings() {
        encodeSet(settings, kSettings)
        rescheduleNotifications()
    }

    func saveApiKey(_ key: String) {
        apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(apiKey, forKey: kApiKey)
    }

    func saveMemories() { encodeSet(memories, kMemories) }

    func addMemory(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        memories.append(MemoryFact(text: t))
        saveMemories()
    }

    func deleteMemory(at offsets: IndexSet) {
        memories.remove(atOffsets: offsets)
        saveMemories()
    }

    func saveUser() { encodeSet(user, kUser) }

    func setAvatar(_ data: Data?) {
        avatarData = data
        if let data { UserDefaults.standard.set(data, forKey: kAvatar) }
        else { UserDefaults.standard.removeObject(forKey: kAvatar) }
    }

    func saveEvents() { encodeSet(events, kEvents) }

    func addEvent(_ text: String, date: Date) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        events.append(SharedEvent(date: date, text: t))
        events.sort { $0.date < $1.date }
        saveEvents()
    }

    func deleteEvent(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
        saveEvents()
    }

    func clearHistory() {
        messages = []
        mood = Mood()
        messages.append(Message(
            role: .assistant,
            content: "……我们之前认识吗？算了，重新开始吧。",
            time: Date()))
        persist()
    }

    func clearMemories() {
        memories = []
        saveMemories()
    }

    // MARK: - 关系

    var intimacyLabel: String {
        switch mood.trust {
        case ..<25: return "还在试探"
        case ..<50: return "刚熟起来"
        case ..<70: return "挺聊得来"
        case ..<85: return "无话不谈"
        default: return "老搭子了"
        }
    }

    var daysKnown: Int {
        max(0, Calendar.current.dateComponents([.day], from: firstMet, to: Date()).day ?? 0)
    }

    // MARK: - 主动开场

    private func proactiveOpener(gapHours: Int) -> String? {
        guard gapHours >= 3 else { return nil }
        if gapHours >= 24 {
            return mood.trust > 60
                ? "一天多没见你了，还以为你把我删了呢。"
                : "哟，失踪人口回来了？一天多没影。"
        }
        if gapHours >= 8 { return "忙完了？我可等你半天了。" }
        return mood.grumpiness > 60 ? "几个小时不理人，挺忙啊你。" : "回来啦，刚跑哪去了？"
    }

    // MARK: - 通知

    func rescheduleNotifications() {
        NotificationManager.shared.scheduleProactive(
            mood: mood, persona: persona, settings: settings)
    }

    // MARK: - 收发

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        messages.append(Message(role: .user, content: trimmed, time: Date()))
        mood.react(to: trimmed)
        isSending = true
        persist()

        do {
            let reply = try await DeepSeekService(apiKey: apiKey)
                .reply(history: messages, persona: persona, user: user,
                       memories: memories, events: events, mood: mood)
            messages.append(Message(role: .assistant, content: reply, time: Date()))
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            messages.append(Message(role: .assistant, content: "（\(msg)）", time: Date()))
        }

        isSending = false
        persist()
        rescheduleNotifications()
    }
}
