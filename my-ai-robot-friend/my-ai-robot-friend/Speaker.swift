//
//  Speaker.swift
//  阿默 —— 语音朗读（TTS，无需权限）
//
//  注意：iOS 模拟器上 AVSpeechSynthesizer 通常不出声（会上报 start/finish 但无音频），
//  这是模拟器的已知限制，真机上正常。
//

import AVFoundation

final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    private init() {}

    /// 选中文语音：优先 zh-CN，退回任意 zh 开头的，再退回系统默认。
    private lazy var chineseVoice: AVSpeechSynthesisVoice? = {
        if let v = AVSpeechSynthesisVoice(language: "zh-CN") { return v }
        if let v = AVSpeechSynthesisVoice.speechVoices()
            .first(where: { $0.language.hasPrefix("zh") }) { return v }
        return nil
    }()

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        // .playback：不受静音开关影响；.duckOthers：压低其他音频
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    func speak(_ text: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        activateSession()

        let u = AVSpeechUtterance(string: clean)
        u.voice = chineseVoice
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        u.pitchMultiplier = 1.0
        synth.speak(u)
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }
}
