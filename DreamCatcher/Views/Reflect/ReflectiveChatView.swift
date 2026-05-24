import SwiftUI

struct ReflectiveChatView: View {
    let dream: Dream
    var lifeContext: String?
    @Environment(\.dismiss) private var dismiss

    @StateObject private var speech = SpeechCaptureService()
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var preDictationText = ""
    @FocusState private var isInputFocused: Bool

    private var openingPrompt: String {
        if AppSettings.interpretationLens == .islamicReflection || AppSettings.interpretationLens == .both {
            return "Anything in your life — or on your heart — feel connected to this dream?"
        }
        return "Does anything in your life feel connected to this dream?"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DreamscapeBackground(intensity: .deep)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(20)
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let last = messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    inputBar
                }
            }
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DreamTheme.lavender)
                }
            }
            .onAppear {
                if messages.isEmpty {
                    messages.append(ChatMessage(text: openingPrompt, isUser: false))
                }
            }
            .onDisappear {
                if speech.isRecording { speech.stopRecording() }
            }
            .onChange(of: speech.transcript) { _, newValue in
                guard speech.isRecording else { return }
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    inputText = preDictationText
                } else if preDictationText.isEmpty {
                    inputText = newValue
                } else {
                    inputText = preDictationText + " " + newValue
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                speech.isRecording ? "Listening…" : "Type or tap the mic",
                text: $inputText,
                axis: .vertical
            )
            .font(.system(size: 15, weight: .light))
            .foregroundStyle(DreamTheme.moonlight)
            .focused($isInputFocused)
            .lineLimit(1...4)
            .disabled(speech.isRecording)

            micButton

            if !trimmedInput.isEmpty && !speech.isRecording {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DreamTheme.lavender)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Send")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DreamTheme.memoryFog.opacity(0.6))
        .animation(.easeInOut(duration: 0.2), value: speech.isRecording)
        .animation(.easeInOut(duration: 0.2), value: trimmedInput.isEmpty)
    }

    private var trimmedInput: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var micButton: some View {
        Button {
            toggleRecording()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        speech.isRecording
                            ? DreamTheme.sunsetOrange.opacity(0.4)
                            : DreamTheme.lavender.opacity(0.25)
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(
                                speech.isRecording
                                    ? DreamTheme.sunsetOrange.opacity(0.6)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .scaleEffect(speech.isRecording ? 1.0 + CGFloat(speech.audioLevel) * 0.15 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: speech.audioLevel)

                if speech.isRecording {
                    ListeningWaveform(level: speech.audioLevel)
                        .frame(width: 22, height: 18)
                        .foregroundStyle(DreamTheme.creamDream)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DreamTheme.creamDream)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: speech.isRecording)
        .accessibilityLabel(speech.isRecording ? "Stop dictation" : "Start dictation")
    }

    private func toggleRecording() {
        if speech.isRecording {
            speech.stopRecording()
            return
        }

        isInputFocused = false

        Task {
            if !speech.permissionGranted {
                await speech.requestPermissions()
            }
            guard speech.permissionGranted else { return }
            preDictationText = trimmedInput
            speech.startRecording()
        }
    }

    private func sendMessage() {
        let text = trimmedInput
        guard !text.isEmpty else { return }

        if speech.isRecording { speech.stopRecording() }
        preDictationText = ""

        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let response = DreamReconstructionService.shared.generateReflectiveResponse(
                for: text,
                dream: dream,
                lifeContext: lifeContext
            )
            messages.append(ChatMessage(text: response, isUser: false))
        }
    }
}

struct ListeningWaveform: View {
    let level: Float
    private let barCount = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let gap: CGFloat = 2
                let totalGap = gap * CGFloat(barCount - 1)
                let barWidth = max(1.5, (size.width - totalGap) / CGFloat(barCount))
                let baseLevel = max(0.18, CGFloat(level))

                for i in 0..<barCount {
                    let phase = Double(i) * 0.7
                    let wave = 0.5 + 0.5 * sin(t * 6 + phase)
                    let height = size.height * (0.28 + baseLevel * CGFloat(wave) * 1.3)
                    let clampedHeight = min(max(height, size.height * 0.18), size.height)
                    let x = CGFloat(i) * (barWidth + gap)
                    let y = (size.height - clampedHeight) / 2
                    let rect = CGRect(x: x, y: y, width: barWidth, height: clampedHeight)
                    let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                    context.fill(path, with: .color(DreamTheme.creamDream))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }

            Text(message.text)
                .font(.system(size: 15, weight: .light, design: message.isUser ? .default : .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(message.isUser ? 0.9 : 0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.isUser
                        ? DreamTheme.lavender.opacity(0.25)
                        : DreamTheme.memoryFog.opacity(0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}
