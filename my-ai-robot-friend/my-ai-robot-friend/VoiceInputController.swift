//
//  VoiceInputController.swift
//  my-ai-robot-friend
//

import AVFoundation
import Combine
import Speech
import SwiftUI

@MainActor
final class VoiceInputController: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var baseText = ""

    func toggle(baseText: String) {
        if isListening {
            stop()
        } else {
            Task { await start(baseText: baseText) }
        }
    }

    func start(baseText: String) async {
        guard !isListening else { return }
        errorMessage = nil
        self.baseText = baseText.trimmingCharacters(in: .whitespacesAndNewlines)

        let speechAllowed = await requestSpeechAuthorization()
        let micAllowed = await requestMicrophoneAuthorization()
        guard speechAllowed, micAllowed else {
            errorMessage = "需要允许麦克风和语音识别权限。"
            return
        }

        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "当前语音识别不可用。"
            return
        }

        do {
            try configureAudioSession()
            try beginRecognition(with: recognizer)
            withAnimation(GenUIMotion.quick) {
                isListening = true
            }
        } catch VoiceInputError.noMicrophone {
            stop()
            errorMessage = "这台设备/模拟器没有可用麦克风，语音输入请在真机上用。"
        } catch {
            stop()
            errorMessage = "语音输入启动失败。"
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        withAnimation(GenUIMotion.quick) {
            isListening = false
        }
    }

    private func beginRecognition(with recognizer: SFSpeechRecognizer) throws {
        task?.cancel()
        task = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        // 模拟器/无麦克风时 sampleRate 可能为 0，直接 installTap 会崩。先拦住。
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw VoiceInputError.noMicrophone
        }
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = self.combinedText(with: result.bestTranscription.formattedString)
                }
                if error != nil || result?.isFinal == true {
                    self.stop()
                }
            }
        }
    }

    private func combinedText(with recognized: String) -> String {
        let clean = recognized.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !baseText.isEmpty else { return clean }
        guard !clean.isEmpty else { return baseText }
        return baseText + " " + clean
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    enum VoiceInputError: Error {
        case noMicrophone
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        }
    }
}
