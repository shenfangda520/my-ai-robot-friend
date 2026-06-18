//
//  NotificationManager.swift
//  阿默 —— 主动找你（本地通知）
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// 根据情绪、人设、设置，安排一批“主动找你”的本地通知。
    /// 每次调用都会重置——所以只要你一回消息，倒计时就重新开始。
    func scheduleProactive(mood: Mood, persona: Persona, settings: AppSettings) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard settings.notificationsEnabled else { return }

        var items: [(TimeInterval, String)] = []

        // 1) 你不理它，过几小时它来戳你。主动性越高，戳得越勤。
        let nudges = Self.nudgeLines(mood: mood)
        let factor = 2.0 - Double(persona.proactiveness) / 100.0  // 1.0(勤) ~ 2.0(懒)
        let base: [TimeInterval] = [2.5 * 3600, 6 * 3600, 11 * 3600]
        for (i, d) in base.enumerated() {
            items.append((d * factor, nudges[i % nudges.count]))
        }

        // 2) 深夜关怀
        if settings.nightCheckIn, let night = Self.secondsUntil(hour: 23, minute: 40), night > 120 {
            items.append((night, "都几点了还不睡？手机放下，眼睛不要了啊。"))
        }
        // 3) 早安
        if settings.morningGreeting, let morning = Self.secondsUntil(hour: 9, minute: 0), morning > 120 {
            items.append((morning, "起了没？别又睡到中午。"))
        }

        for (delay, body) in items {
            let content = UNMutableNotificationContent()
            content.title = persona.name
            content.body = body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(60, delay), repeats: false)
            center.add(UNNotificationRequest(
                identifier: UUID().uuidString, content: content, trigger: trigger))
        }
    }

    static func nudgeLines(mood: Mood) -> [String] {
        if mood.grumpiness > 65 {
            return ["人呢？问你话不回，搞失踪啊。",
                    "行，挺有种，敢晾着我。",
                    "我可没那么多耐心等你。"]
        }
        if mood.trust > 70 {
            return ["在干嘛呢，突然有点想你了。",
                    "今天过得咋样？跟我唠两句呗。",
                    "没事，就是想戳戳你。"]
        }
        return ["喂，活着没？好久没动静了。",
                "无聊死了，来陪我聊会儿。",
                "你是不是把我忘手机里吃灰了。"]
    }

    static func secondsUntil(hour: Int, minute: Int) -> TimeInterval? {
        let cal = Calendar.current
        guard let next = cal.nextDate(
            after: Date(),
            matching: DateComponents(hour: hour, minute: minute),
            matchingPolicy: .nextTime) else { return nil }
        return next.timeIntervalSince(Date())
    }
}
