import SwiftUI
import SwiftData

struct BedsideCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var speech = SpeechCaptureService()
    @State private var selectedEmotions: Set<DreamEmotion> = []
    @State private var selectedColors: Set<String> = []
    @State private var fragmentText = ""
    @State private var showReconstructionOffer = false
    @State private var savedDream: Dream?
    @State private var isSaving = false
    @State private var showSavedConfirmation = false
    @State private var showOptionalDetails = false
    @State private var finishedRecordingSession = false

    private let colorOptions = ["Purple", "Blue", "Red", "Gold", "Green", "Silver", "Black", "White"]

    private var hasRecordedTranscript: Bool {
        !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isReviewing: Bool {
        !speech.isRecording && finishedRecordingSession
    }

    var body: some View {
        ZStack {
            DreamscapeBackground(intensity: .bedside, audioLevel: speech.audioLevel)
                .ignoresSafeArea()

            if showSavedConfirmation {
                savedConfirmationView
            } else if showReconstructionOffer, let dream = savedDream {
                ReconstructionOfferView(dream: dream) {
                    dismiss()
                }
            } else {
                captureContent
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .task {
            await speech.requestPermissions()
            AmbientAudioService.shared.startBedsideAmbience()
        }
        .onDisappear {
            speech.stopRecording()
            AmbientAudioService.shared.stop()
        }
    }

    private var captureContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.5))
                        .padding(12)
                }
                Spacer()
            }
            .padding(.horizontal, 8)

            promptHeader
                .padding(.horizontal, 24)
                .padding(.top, 28)

            if let errorMessage = speech.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.orange.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            if speech.isRecording || isReviewing || !speech.transcript.isEmpty {
                liveTranscriptView
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer(minLength: 16)

            if isReviewing {
                if showOptionalDetails {
                    fragmentSection
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOptionalDetails.toggle()
                    }
                } label: {
                    Text(showOptionalDetails ? "Hide details" : "Add feelings or colors")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.55))
                }
                .padding(.bottom, 8)
            } else if !speech.isRecording {
                fragmentSection
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            }

            micButton
                .padding(.bottom, 20)

            if !speech.transcript.isEmpty || !selectedEmotions.isEmpty {
                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: speech.transcript)
        .animation(.easeInOut(duration: 0.6), value: speech.isRecording)
        .animation(.easeInOut(duration: 0.3), value: showOptionalDetails)
    }

    private var promptHeader: some View {
        VStack(spacing: 12) {
            if speech.isRecording {
                Text("Listening…")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                recordingTimerView
            } else if isReviewing {
                Text("Here's what you captured")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("Recorded for \(SpeechCaptureService.formattedDuration(speech.lastRecordingDuration))")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(DreamTheme.lavender.opacity(0.9))
            } else {
                Text("Tell me what you remember")
                    .font(.system(size: 22, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("Even a single word is enough")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.78))
                    .tracking(0.3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var liveTranscriptView: some View {
        ScrollView {
            if speech.transcript.isEmpty {
                Text(speech.isRecording
                     ? "Your words will appear here…"
                     : "No words picked up — tap the mic to try again, or add a note below.")
                    .font(.system(size: speech.isRecording ? 17 : 16, weight: .regular, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.65))
                    .multilineTextAlignment(speech.isRecording ? .leading : .center)
                    .frame(maxWidth: .infinity, alignment: speech.isRecording ? .leading : .center)
            } else if speech.isRecording {
                Text(speech.transcript)
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(Array(speech.highlightedWords(in: speech.transcript).enumerated()), id: \.offset) { index, item in
                        Text(item.0)
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundStyle(item.1 ? DreamTheme.softGlow : DreamTheme.moonlight.opacity(0.85))
                            .symbolGlow(item.1)
                            .shimmerIn(delay: Double(index) * 0.04)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: speech.isRecording ? 280 : (isReviewing ? 220 : 120))
    }

    private var fragmentSection: some View {
        VStack(spacing: 16) {
            emotionChips
            colorChips
            fragmentInput
        }
    }

    private var emotionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How did it feel?")
                .font(.caption)
                .foregroundStyle(DreamTheme.moonlight.opacity(0.4))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DreamEmotion.allCases) { emotion in
                        ChipButton(
                            title: emotion.displayName,
                            isSelected: selectedEmotions.contains(emotion),
                            color: DreamTheme.emotionColor(emotion)
                        ) {
                            if selectedEmotions.contains(emotion) {
                                selectedEmotions.remove(emotion)
                            } else {
                                selectedEmotions.insert(emotion)
                            }
                        }
                    }
                }
            }
        }
    }

    private var colorChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Any colors?")
                .font(.caption)
                .foregroundStyle(DreamTheme.moonlight.opacity(0.4))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(colorOptions, id: \.self) { color in
                        ChipButton(
                            title: color,
                            isSelected: selectedColors.contains(color),
                            color: swatch(for: color),
                            dotColor: swatch(for: color)
                        ) {
                            if selectedColors.contains(color) {
                                selectedColors.remove(color)
                            } else {
                                selectedColors.insert(color)
                            }
                        }
                    }
                }
            }
        }
    }

    private func swatch(for color: String) -> Color {
        switch color {
        case "Purple": return DreamTheme.electricViolet
        case "Blue":   return Color(red: 0.38, green: 0.55, blue: 0.88)
        case "Red":    return Color(red: 0.88, green: 0.40, blue: 0.42)
        case "Gold":   return DreamTheme.goldDust
        case "Green":  return Color(red: 0.45, green: 0.72, blue: 0.55)
        case "Silver": return Color(red: 0.80, green: 0.82, blue: 0.86)
        case "Black":  return Color(red: 0.14, green: 0.14, blue: 0.20)
        case "White":  return DreamTheme.creamDream
        default:       return DreamTheme.lavender
        }
    }

    private var fragmentInput: some View {
        HStack {
            TextField("Add a word or detail", text: $fragmentText)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(DreamTheme.moonlight)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(DreamTheme.memoryFog.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !fragmentText.isEmpty {
                Button {
                    // Fragment saved on dream save
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DreamTheme.lavender)
                }
            }
        }
    }

    private var recordingTimerView: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let elapsed = speech.recordingStartedAt.map {
                context.date.timeIntervalSince($0)
            } ?? 0

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red.opacity(0.85))
                    .frame(width: 8, height: 8)

                Text(SpeechCaptureService.formattedDuration(elapsed))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.85))
            }
        }
    }

    private var micButton: some View {
        Button {
            if speech.isRecording {
                speech.stopRecording()
                finishedRecordingSession = true
                AmbientAudioService.shared.playChime()
            } else {
                finishedRecordingSession = false
                showOptionalDetails = false
                Task {
                    AmbientAudioService.shared.stop()
                    if !speech.permissionGranted {
                        await speech.requestPermissions()
                    }
                    guard speech.permissionGranted else { return }
                    speech.startRecording()
                }
            }
        } label: {
            nebulaMicCore
                .nebulaMicGlow(audioLevel: speech.audioLevel, idlePulse: !speech.isRecording)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: speech.isRecording)
    }

    private var nebulaMicCore: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            speech.isRecording ? DreamTheme.electricViolet.opacity(0.55) : DreamTheme.electricViolet.opacity(0.28),
                            DreamTheme.sunsetOrange.opacity(0.12)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(1.0 + CGFloat(speech.audioLevel) * 0.1)
                .animation(.easeOut(duration: 0.1), value: speech.audioLevel)
                .breathingPulse(intensity: speech.isRecording ? 1.5 : 0.8)

            Image(systemName: speech.isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(DreamTheme.creamDream)
                .symbolEffect(.variableColor.iterative, isActive: speech.isRecording)
        }
    }

    private var saveButton: some View {
        Button {
            saveDream()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(DreamTheme.moonlight)
                } else {
                    Text("Save")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DreamTheme.lavender.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(DreamTheme.moonlight)
        }
        .disabled(isSaving)
    }

    private var savedConfirmationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(DreamTheme.lavender)
                .breathingPulse()

            Text("Dream captured")
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight)

            Text("Recorded for \(SpeechCaptureService.formattedDuration(speech.lastRecordingDuration))")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(DreamTheme.lavender.opacity(0.9))

            if !speech.transcript.isEmpty {
                Text("\"\(transcriptPreview)\"")
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }

            Text("You can come back to this anytime")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
        }
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showSavedConfirmation = false
                    showReconstructionOffer = true
                }
            }
        }
    }

    private var transcriptPreview: String {
        let trimmed = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 60 else { return trimmed }
        return String(trimmed.prefix(60)) + "…"
    }

    private func saveDream() {
        isSaving = true
        speech.stopRecording()

        let dream = Dream(rawTranscript: speech.transcript)
        dream.emotions = selectedEmotions.map(\.rawValue)
        dream.dominantEmotion = selectedEmotions.first?.rawValue
        dream.colors = Array(selectedColors)

        if !fragmentText.isEmpty {
            let fragment = DreamFragment(content: fragmentText, kind: .word)
            dream.fragments.append(fragment)
        }

        for emotion in selectedEmotions {
            let fragment = DreamFragment(content: emotion.displayName, kind: .emotion)
            dream.fragments.append(fragment)
        }

        for color in selectedColors {
            let fragment = DreamFragment(content: color, kind: .color)
            dream.fragments.append(fragment)
        }

        modelContext.insert(dream)

        Task {
            await DreamReconstructionService.shared.processDream(dream, context: modelContext)
            await PatternEngine.shared.updatePatterns(for: dream, context: modelContext)

            isSaving = false
            savedDream = dream
            withAnimation {
                showSavedConfirmation = true
            }
        }
    }
}

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    var dotColor: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 9, height: 9)
                        .overlay(
                            Circle()
                                .stroke(DreamTheme.creamDream.opacity(0.25), lineWidth: 0.5)
                        )
                }
                Text(title)
                    .font(.system(size: 13, weight: .light))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.35) : DreamTheme.memoryFog.opacity(0.4))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.opacity(0.6) : Color.clear, lineWidth: 1)
            )
            .foregroundStyle(DreamTheme.moonlight.opacity(isSelected ? 1 : 0.7))
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
