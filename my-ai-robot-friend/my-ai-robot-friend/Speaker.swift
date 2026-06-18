//
//  Speaker.swift
//  阿默 —— 语音朗读（TTS，无需权限）
//

import AVFoundation

final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    private init() {}

    func speak(_ text: String) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        u.rate = 0.5
        u.pitchMultiplier = 1.0
        synth.speak(u)
    }
}
