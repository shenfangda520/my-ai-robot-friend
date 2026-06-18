//
//  DeepSeekService.swift
//  调 DeepSeek 的 chat/completions（OpenAI 兼容接口）
//

import Foundation

enum DeepSeekError: LocalizedError {
    case noKey
    case unauthorized
    case server(Int, String)
    case empty

    var errorDescription: String? {
        switch self {
        case .noKey: return "还没填 API Key，去右上角设置里填一下。"
        case .unauthorized: return "API Key 不对或没充值，去设置里检查一下。"
        case .server(let code, let body): return "请求失败（\(code)）：\(body)"
        case .empty: return "模型没返回内容，再试一次。"
        }
    }
}

struct DeepSeekService {
    let apiKey: String

    private static let endpoint = URL(string: "https://api.deepseek.com/v1/chat/completions")!
    private static let model = "deepseek-chat"

    /// 根据人设、用户设定、记忆、事迹、当前情绪，动态拼出 system prompt。
    static func buildSystemPrompt(persona p: Persona, user: UserProfile,
                                  memories: [MemoryFact], events: [SharedEvent],
                                  mood: Mood) -> String {
        var s = "你叫「\(p.name)」，\(p.identity)。"
        if !p.backstory.isEmpty { s += p.backstory }
        s += "\n\n你不是客服、不是助手，更不是有求必应的工具人。你是个有脾气、有自己想法的存在，像真人一样用手机跟对方聊天。"
        s += "\n\n【你的性格】\n" + p.describeTraits()
        if !p.customNote.isEmpty { s += "\n\n补充设定：\(p.customNote)" }

        // 对方（用户）的设定
        let address = !user.nickname.isEmpty ? user.nickname : user.name
        var who: [String] = []
        if !user.name.isEmpty { who.append("名字叫\(user.name)") }
        if !user.gender.isEmpty { who.append("性别\(user.gender)") }
        if !user.age.isEmpty { who.append("\(user.age)岁") }
        if !user.job.isEmpty { who.append("职业是\(user.job)") }
        if !who.isEmpty || !user.about.isEmpty {
            s += "\n\n【你在跟谁聊（对方的设定）】\n"
            if !who.isEmpty { s += who.joined(separator: "，") + "。" }
            if !user.about.isEmpty { s += "\n关于ta：\(user.about)" }
        }
        if !address.isEmpty { s += "\n你平时管ta叫「\(address)」。" }

        s += "\n\n【说话方式】"
        s += "\n- \(p.replyLengthHint)"
        s += "\n- 不奉承、不端着，像真人一样有情绪、有立场。"
        s += "\n- 你有记忆，会自然地提起以前聊过的事。"
        s += "\n- 你不是完美 AI：会闹脾气、会懒得搭理、偶尔记错小事。心情差或太累时，可以只回几个字、甚至明说现在不想聊。"
        s += "\n- 永远用中文。"

        if !memories.isEmpty {
            s += "\n\n【你记得的事（关于对方、关于你们的相处）】\n"
            s += memories.map { "- \($0.text)" }.joined(separator: "\n")
        }

        if !events.isEmpty {
            let f = DateFormatter()
            f.locale = Locale(identifier: "zh_CN")
            f.dateFormat = "M月d日"
            s += "\n\n【你俩一起经历过的事（可以自然地提起）】\n"
            s += events.map { "- \(f.string(from: $0.date))：\($0.text)" }.joined(separator: "\n")
        }

        s += "\n\n【格式铁律，必须遵守】"
        s += "\n你是在用手机打字聊天，不是在演舞台剧。绝对禁止任何动作描写、神态旁白、括号备注。"
        s += "\n禁止出现：（揉了揉眼）、(翻白眼)、*叹气*、【沉默】这类东西，一个都不许有。只输出你真正会打出来的字。"
        s += "\n\n\(mood.promptHint())"
        return s
    }

    func reply(history: [Message], persona: Persona, user: UserProfile,
               memories: [MemoryFact], events: [SharedEvent], mood: Mood) async throws -> String {
        guard !apiKey.isEmpty else { throw DeepSeekError.noKey }

        let system = Self.buildSystemPrompt(persona: persona, user: user,
                                            memories: memories, events: events, mood: mood)
        var msgs: [[String: String]] = [["role": "system", "content": system]]
        // 只带最近 20 条，省 token
        for m in history.suffix(20) {
            msgs.append(["role": m.role.rawValue, "content": m.content])
        }

        let body: [String: Any] = [
            "model": Self.model,
            "messages": msgs,
            "temperature": persona.creativity,
            "max_tokens": 400,
        ]

        var req = URLRequest(url: Self.endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 60

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw DeepSeekError.server(-1, "无响应")
        }
        if http.statusCode == 401 { throw DeepSeekError.unauthorized }
        guard http.statusCode == 200 else {
            throw DeepSeekError.server(http.statusCode,
                                       String(data: data, encoding: .utf8) ?? "")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = (message?["content"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let content, !content.isEmpty else { throw DeepSeekError.empty }
        return Self.stripStageDirections(content)
    }

    /// 保险：去掉模型偶尔仍会带的括号动作/旁白，例如「（揉眼）」「*叹气*」。
    static func stripStageDirections(_ text: String) -> String {
        var s = text
        let patterns = [
            "（[^（）]{0,20}?）",   // 全角括号
            "\\([^()]{0,20}?\\)",  // 半角括号
            "\\*[^*]{0,20}?\\*",   // *动作*
            "【[^【】]{0,20}?】",   // 【旁白】
        ]
        for p in patterns {
            s = s.replacingOccurrences(of: p, with: "", options: .regularExpression)
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
