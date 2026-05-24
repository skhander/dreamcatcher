import SwiftUI
import SwiftData

struct DreamDetailView: View {
    @Bindable var dream: Dream
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var lifeEntries: [LifeEntry]

    @State private var selectedLayer: InterpretationLayer = .emotionalMirror
    @State private var showReflectiveChat = false
    @State private var showDeleteConfirmation = false
    @State private var lens = AppSettings.interpretationLens
    @State private var showJungian = AppSettings.showJungianSymbolic
    @State private var userReflectionText: String = ""

    private var visibleLayers: [InterpretationLayer] {
        InterpretationLayer.visibleLayers(lens: lens, showJungian: showJungian)
    }

    private var linkedLifeContext: String? {
        lifeEntries.first(where: { $0.linkedDreamID == dream.id })?.tags.first
    }

    var body: some View {
        ZStack {
            DreamscapeBackground(intensity: .standard)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    narrativeSection
                    symbolsSection
                    lifeConnectionSection
                    interpretationTabs
                    interpretationContent
                    userReflectionSection
                    reflectivePrompt
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(dream.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(DreamTheme.lavender)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
                }
            }
        }
        .confirmationDialog(
            "Delete this dream?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                DreamDeletionService.delete(dream, context: modelContext, lifeEntries: lifeEntries)
                dismiss()
            }
        } message: {
            Text("This can't be undone.")
        }
        .sheet(isPresented: $showReflectiveChat) {
            ReflectiveChatView(dream: dream, lifeContext: linkedLifeContext ?? dream.lifeEventNote)
        }
        .onAppear {
            lens = AppSettings.interpretationLens
            showJungian = AppSettings.showJungianSymbolic
            userReflectionText = dream.userReflection ?? ""
            if !visibleLayers.contains(selectedLayer) {
                selectedLayer = visibleLayers.first ?? .emotionalMirror
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let emotion = dream.primaryEmotion {
                HStack(spacing: 8) {
                    Circle()
                        .fill(DreamTheme.emotionColor(emotion))
                        .frame(width: 10, height: 10)
                    Text(emotion.displayName)
                        .font(.caption)
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.7))
                }
            }

            if !dream.emotions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(dream.emotions, id: \.self) { e in
                            if let emotion = DreamEmotion(rawValue: e) {
                                Text(emotion.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(DreamTheme.emotionColor(emotion).opacity(0.2))
                                    .clipShape(Capsule())
                                    .foregroundStyle(DreamTheme.moonlight.opacity(0.8))
                            }
                        }
                    }
                }
            }
        }
    }

    private var narrativeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let narrative = dream.reconstructedNarrative {
                Text(narrative)
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight)
                    .lineSpacing(10)
            }

            if !dream.rawTranscript.isEmpty {
                DisclosureGroup {
                    Text(dream.rawTranscript)
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
                        .italic()
                        .padding(.top, 8)
                } label: {
                    Text("What you said")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender.opacity(0.7))
                }
                .tint(DreamTheme.lavender)
            }
        }
        .padding(20)
        .glassCard()
    }

    private var symbolsSection: some View {
        Group {
            if !dream.symbols.isEmpty || !dream.colors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Symbols")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender)

                    FlowLayout(spacing: 8) {
                        ForEach(dream.symbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DreamTheme.lavender.opacity(0.15))
                                .clipShape(Capsule())
                                .foregroundStyle(DreamTheme.softGlow)
                        }
                        ForEach(dream.colors, id: \.self) { color in
                            Text(color)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DreamTheme.memoryFog.opacity(0.5))
                                .clipShape(Capsule())
                                .foregroundStyle(DreamTheme.moonlight.opacity(0.7))
                        }
                    }
                }
                .padding(20)
                .glassCard()
            }
        }
    }

    private var lifeConnectionSection: some View {
        Group {
            if let note = dream.lifeEventNote, !note.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Life connection")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender)
                    Text(note)
                        .font(.system(size: 15, weight: .light, design: .serif))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.85))
                }
                .padding(20)
                .glassCard()
            }
        }
    }

    private var interpretationTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visibleLayers) { layer in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedLayer = layer
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: layer.icon)
                                .font(.caption)
                            Text(layer.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedLayer == layer
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [DreamTheme.electricViolet.opacity(0.45), DreamTheme.sunsetOrange.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                : AnyShapeStyle(DreamTheme.memoryFog.opacity(0.3))
                        )
                        .clipShape(Capsule())
                        .foregroundStyle(selectedLayer == layer ? DreamTheme.moonlight : DreamTheme.moonlight.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var interpretationContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedLayer.rawValue)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DreamTheme.lavender)

            Text(interpretationText)
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.9))
                .lineSpacing(8)
                .animation(.easeInOut, value: selectedLayer)
        }
        .padding(20)
        .glassCard()
    }

    private var interpretationText: String {
        switch selectedLayer {
        case .emotionalMirror:
            return dream.emotionalMirror ?? "Sit with what lingered after waking. That feeling usually says more than the plot."
        case .modernPsychology:
            return dream.modernPsychology ?? "Your mind may be working through something recent. More dreams will make the pattern clearer."
        case .islamicReflection:
            return dream.islamicReflection ?? "Reflective guidance only, not a religious ruling. For significant dreams, talk to someone knowledgeable."
        case .jungianSymbolic:
            return dream.jungianSymbolic ?? "Every symbol here is personal first. What it means to you will get clearer over time."
        case .narrativeReflection:
            return dream.narrativeReflection ?? "Save a few more dreams and patterns across them will start to show up."
        }
    }

    private var userReflectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What you think it means")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DreamTheme.lavender)

            TextField("Your take…", text: $userReflectionText, axis: .vertical)
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight)
                .lineLimit(2...6)
                .onChange(of: userReflectionText) { _, newValue in
                    dream.userReflection = newValue.isEmpty ? nil : newValue
                    try? modelContext.save()
                }
        }
        .padding(20)
        .glassCard()
    }

    private var reflectivePrompt: some View {
        Button {
            showReflectiveChat = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Talk it through")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DreamTheme.moonlight)

                Text("Does anything in your life feel connected to this dream?")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
