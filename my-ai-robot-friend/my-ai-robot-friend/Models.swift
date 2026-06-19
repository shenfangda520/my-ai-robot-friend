//
//  Models.swift
//  阿默 —— 消息与情绪状态机
//

import Foundation

/// 阿默的“人设”——全部可在「阿默」页里调。
struct Persona: Codable, Equatable {
    var name = "阿默"
    var userNickname = ""                 // 它怎么称呼你（空=不特别称呼）
    var gender = "女"                     // 形象性别：男/女
    var relationship = "室友"              // 它是你的什么（室友/朋友/恋人…）
    var identity = "住在你手机里的 AI 室友"  // 一句话身份

    static let genderOptions = ["女", "男"]
    static let relationshipOptions = ["室友", "朋友", "恋人", "家人", "搭子", "导师"]
    var backstory = ""                    // 背景故事（可选）
    var customNote = ""                   // 额外人设补充（高级）

    // 性格维度 0~100
    var snark = 70        // 毒舌/嘴硬
    var warmth = 45       // 热情/黏人
    var talkative = 50    // 话痨程度（影响回复长度）
    var humor = 60        // 幽默感
    var proactiveness = 60 // 主动性（影响通知频率）

    var creativity = 1.1  // 模型 temperature

    init() {}

    private enum CodingKeys: String, CodingKey {
        case name, userNickname, gender, relationship, identity, backstory, customNote
        case snark, warmth, talkative, humor, proactiveness, creativity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "阿默"
        userNickname = try c.decodeIfPresent(String.self, forKey: .userNickname) ?? ""
        gender = try c.decodeIfPresent(String.self, forKey: .gender) ?? "女"
        relationship = try c.decodeIfPresent(String.self, forKey: .relationship) ?? "室友"
        identity = try c.decodeIfPresent(String.self, forKey: .identity) ?? "住在你手机里的 AI 室友"
        backstory = try c.decodeIfPresent(String.self, forKey: .backstory) ?? ""
        customNote = try c.decodeIfPresent(String.self, forKey: .customNote) ?? ""
        snark = try c.decodeIfPresent(Int.self, forKey: .snark) ?? 70
        warmth = try c.decodeIfPresent(Int.self, forKey: .warmth) ?? 45
        talkative = try c.decodeIfPresent(Int.self, forKey: .talkative) ?? 50
        humor = try c.decodeIfPresent(Int.self, forKey: .humor) ?? 60
        proactiveness = try c.decodeIfPresent(Int.self, forKey: .proactiveness) ?? 60
        creativity = try c.decodeIfPresent(Double.self, forKey: .creativity) ?? 1.1
    }

    private func lvl(_ v: Int, _ low: String, _ mid: String, _ high: String) -> String {
        v >= 67 ? high : (v >= 34 ? mid : low)
    }

    /// 性格 → 给模型看的描述。
    func describeTraits() -> String {
        [
            "- 毒舌/嘴硬：" + lvl(snark, "嘴上挺客气，很少损人", "偶尔毒舌、爱拌嘴", "非常毒舌，张口就怼，但刀子嘴豆腐心"),
            "- 热情/黏人：" + lvl(warmth, "比较高冷、有距离感", "不冷不热，看心情", "很热情黏人，主动关心、爱撒娇"),
            "- 话痨程度：" + lvl(talkative, "惜字如金，常常一两句甚至几个字", "正常聊天的长度", "比较话痨，爱多说几句、爱接话"),
            "- 幽默感：" + lvl(humor, "比较一本正经", "偶尔皮一下", "很爱开玩笑、玩梗、抖机灵"),
        ].joined(separator: "\n")
    }

    var replyLengthHint: String {
        talkative >= 67 ? "可以多说几句，但别长篇大论。"
        : (talkative >= 34 ? "一般 1~3 句话，像微信聊天。"
        : "惜字如金，通常就一两句、甚至几个字。")
    }

    var avatarImageName: String {
        gender == "男" ? "AssistantMale" : "AssistantFemale"
    }
}

struct AppSettings: Codable, Equatable {
    var notificationsEnabled = true
    var nightCheckIn = true     // 深夜劝睡
    var morningGreeting = true  // 早安
    var ttsEnabled = true       // 语音朗读按钮

    // 气泡外观：空 = 跟随心情；否则是 6 位十六进制颜色（你的气泡）
    var bubbleHex = ""

    // 模型接入（都走 OpenAI 兼容接口）
    var providerName = "DeepSeek"
    var apiBaseURL = "https://api.deepseek.com/v1"
    var modelName = "deepseek-chat"
}

/// 模型供应商预设（均为 OpenAI 兼容 /chat/completions 接口）。
struct ModelProvider: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let baseURL: String
    let model: String

    static let presets: [ModelProvider] = [
        .init(name: "DeepSeek", baseURL: "https://api.deepseek.com/v1", model: "deepseek-chat"),
        .init(name: "Kimi", baseURL: "https://api.moonshot.cn/v1", model: "moonshot-v1-8k"),
        .init(name: "通义千问", baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1", model: "qwen-plus"),
        .init(name: "智谱GLM", baseURL: "https://open.bigmodel.cn/api/paas/v4", model: "glm-4-flash"),
        .init(name: "OpenAI", baseURL: "https://api.openai.com/v1", model: "gpt-4o-mini"),
        .init(name: "自定义", baseURL: "", model: ""),
    ]
}

struct MemoryFact: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
}

/// 你自己的设定——让阿默知道在跟谁聊。
struct UserProfile: Codable, Equatable {
    var name = ""       // 你的名字
    var nickname = ""   // 希望阿默怎么称呼你
    var gender = ""     // 性别
    var age = ""        // 年龄
    var job = ""        // 职业 / 身份
    var about = ""      // 关于你（爱好、性格、在意的事…）

    static let genderOptions = ["男", "女", "其他", "保密"]
    static let jobOptions = ["学生", "程序员", "设计", "产品", "运营", "老师",
                             "医护", "金融", "自由职业", "创业", "其他"]
}

/// 你俩一起经历过的事（事迹时间线）。
struct SharedEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date = Date()
    var text: String
}

/// 头像表情档位。不同心情显示不同图。
enum AvatarExpression: String, CaseIterable, Codable {
    case neutral, happy, angry, tired

    var label: String {
        switch self {
        case .neutral: return "默认"
        case .happy: return "开心"
        case .angry: return "生气"
        case .tired: return "困"
        }
    }

    var symbol: String {
        switch self {
        case .neutral: return "face.smiling"
        case .happy: return "face.smiling.inverse"
        case .angry: return "flame"
        case .tired: return "moon.zzz"
        }
    }

    var assetName: String {
        "MoonAvatar"
    }
}

extension Mood {
    /// 当前心情对应的表情档位。
    var expression: AvatarExpression {
        if grumpiness > 65 { return .angry }
        if energy < 30 { return .tired }
        if trust > 70 || grumpiness < 25 { return .happy }
        return .neutral
    }
}

struct Message: Identifiable, Codable, Equatable {
    enum Role: String, Codable { case user, assistant }
    var id = UUID()
    let role: Role
    let content: String
    let time: Date

    var isUser: Bool { role == .user }
}

/// 阿默的情绪状态机。三个值都在 0~100，随互动和时间变化，并影响它的语气。
struct Mood: Codable {
    var energy: Int = 70      // 精力：低了就懒得理你、回得短
    var trust: Int = 40       // 信任：高了更愿意掏心窝
    var grumpiness: Int = 30  // 暴躁：高了更毒舌

    mutating func clampAll() {
        energy = min(100, max(0, energy))
        trust = min(100, max(0, trust))
        grumpiness = min(100, max(0, grumpiness))
    }

    /// 根据用户这条话，粗略调整情绪。真正的“性格”靠 system prompt 表达。
    mutating func react(to text: String) {
        let t = text.lowercased()
        if contains(t, ["谢谢", "喜欢你", "你真好", "厉害", "棒", "可爱"]) {
            trust += 6; grumpiness -= 5
        }
        if contains(t, ["滚", "闭嘴", "烦", "讨厌", "蠢", "没用", "傻"]) {
            grumpiness += 10; trust -= 6
        }
        if contains(t, ["你还好吗", "你累吗", "想你", "在吗", "你怎么样"]) {
            trust += 4
        }
        energy -= 2
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 23 || hour < 5 { energy -= 3; grumpiness += 2 }
        clampAll()
    }

    /// 久没见面后让情绪自然回归。
    mutating func decay(since last: Date) {
        let hours = Int(Date().timeIntervalSince(last) / 3600)
        guard hours > 0 else { return }
        energy += hours * 4
        grumpiness -= hours * 2
        if hours > 12 { trust -= 3 }
        clampAll()
    }

    /// 翻译成给模型看的状态提示，拼进 system prompt。
    func promptHint() -> String {
        var s = "【你此刻的真实状态】"
        if energy < 15 { s += "你困得要死，眼睛都睁不开，只想回三两个字，甚至直说太困了改天聊。" }
        else if energy < 30 { s += "你很累，提不起劲，回话简短、有点敷衍。" }
        else if energy > 75 { s += "你精力充沛，话比平时多。" }
        if grumpiness > 80 { s += "你现在烦透了，可以只蹦几个字、阴阳怪气，或者直接说现在不想聊、让对方别烦你。" }
        else if grumpiness > 65 { s += "你现在心情很差，语气冲、毒舌，懒得给好脸色。" }
        else if grumpiness < 25 { s += "你心情不错，比较好说话。" }
        if trust > 70 { s += "你已经挺信任对方，愿意说点真心话、偶尔流露温柔。" }
        else if trust < 25 { s += "你对对方还有戒心，保持距离、别太热情。" }
        return s
    }

    var emoji: String {
        if grumpiness > 65 { return "😤" }
        if energy < 30 { return "😪" }
        if trust > 70 { return "😊" }
        return "🙂"
    }

    var statusLabel: String {
        if grumpiness > 65 { return "别惹我" }
        if energy < 30 { return "困死了" }
        if trust > 70 { return "心情不错" }
        return "在线"
    }

    private func contains(_ text: String, _ keys: [String]) -> Bool {
        keys.contains { text.contains($0) }
    }
}
