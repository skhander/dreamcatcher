import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechCaptureService: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    @Published var permissionGranted = false
    @Published var errorMessage: String?
    @Published private(set) var recordingStartedAt: Date?
    @Published private(set) var lastRecordingDuration: TimeInterval = 0

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var finalizedTranscript = ""
    private var isStopping = false
    private var stopTimeoutTask: Task<Void, Never>?

    static let symbolKeywords: Set<String> = [
        "ocean", "water", "mother", "father", "child", "dog", "cat", "house",
        "school", "train", "flight", "airport", "stairs", "elevator", "door",
        "forest", "wolf", "bird", "moon", "sun", "fire", "rain", "snow",
        "bridge", "river", "mountain", "cave", "mirror", "window", "road",
        "car", "boat", "ship", "hotel", "room", "bed", "garden", "tree",
        "snake", "spider", "horse", "baby", "stranger", "friend", "teacher"
    ]

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let micStatus = await AVAudioApplication.requestRecordPermission()

        permissionGranted = speechStatus == .authorized && micStatus
        if !permissionGranted {
            errorMessage = "Microphone and speech recognition are needed to capture dreams."
        } else {
            errorMessage = nil
        }
    }

    func startRecording() {
        guard permissionGranted else {
            errorMessage = "Microphone and speech recognition are needed to capture dreams."
            return
        }
        guard !isRecording, !isStopping else { return }

        tearDownRecording(resetDuration: true)

        transcript = ""
        finalizedTranscript = ""
        lastRecordingDuration = 0
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetooth, .duckOthers]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not configure audio session."
            return
        }

        guard setupRecognitionRequest() else {
            tearDownRecording(resetDuration: true)
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.updateAudioLevel(buffer: buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            recordingStartedAt = Date()
        } catch {
            errorMessage = "Could not start audio engine."
            tearDownRecording(resetDuration: true)
        }
    }

    func stopRecording() {
        guard isRecording, !isStopping else { return }

        isStopping = true
        recognitionRequest?.endAudio()

        stopTimeoutTask?.cancel()
        stopTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, isStopping else { return }
            finishStop()
        }
    }

    private func finishStop() {
        stopTimeoutTask?.cancel()
        stopTimeoutTask = nil
        isStopping = false
        tearDownRecording(resetDuration: false)
    }

    private func tearDownRecording(resetDuration: Bool) {
        if !resetDuration, let recordingStartedAt {
            lastRecordingDuration = Date().timeIntervalSince(recordingStartedAt)
        } else if resetDuration {
            lastRecordingDuration = 0
        }
        self.recordingStartedAt = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        isStopping = false
        audioLevel = 0
    }

    @discardableResult
    private func setupRecognitionRequest() -> Bool {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        guard let speechRecognizer else {
            errorMessage = "Speech recognition is not available for your language."
            return false
        }

        guard speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is unavailable. Check your connection or try again."
            return false
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .dictation
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionUpdate(result: result, error: error)
            }
        }

        return true
    }

    private func restartRecognitionSegment() {
        guard isRecording, !isStopping else { return }
        finalizedTranscript = transcript
        _ = setupRecognitionRequest()
    }

    private func handleRecognitionUpdate(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            updateTranscript(with: result.bestTranscription.formattedString)

            if result.isFinal {
                if isStopping {
                    finishStop()
                } else if isRecording {
                    restartRecognitionSegment()
                }
            }
            return
        }

        if isStopping {
            finishStop()
            return
        }

        guard let error, isRecording else { return }

        if isCancellationError(error) {
            return
        }

        restartRecognitionSegment()
    }

    private func updateTranscript(with segment: String) {
        if finalizedTranscript.isEmpty {
            transcript = segment
        } else if segment.isEmpty {
            transcript = finalizedTranscript
        } else {
            transcript = finalizedTranscript + " " + segment
        }
    }

    private func isCancellationError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 216 { return true }
        if nsError.domain == "kLSRErrorDomain", nsError.code == 301 { return true }
        return false
    }

    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frames {
            sum += abs(channelData[i])
        }
        let avg = sum / Float(frames)
        Task { @MainActor in
            self.audioLevel = min(avg * 20, 1.0)
        }
    }

    static func formattedDuration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func highlightedWords(in text: String) -> [(String, Bool)] {
        text.split(separator: " ").map { word in
            let cleaned = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            let isSymbol = Self.symbolKeywords.contains(cleaned)
            return (String(word), isSymbol)
        }
    }
}
