import SwiftUI
import SwiftData

struct LifeThreadBridgeView: View {
    let dream: Dream
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var prompt: LifePrompt
    @State private var selectedChip: String?
    @State private var optionalNote = ""
    @State private var showNoteField = false

    init(dream: Dream, onComplete: @escaping () -> Void) {
        self.dream = dream
        self.onComplete = onComplete
        _prompt = State(initialValue: LifePromptEngine.prompt(for: dream))
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(prompt.mirrorLine)
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.lavender.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(prompt.question)
                    .font(.system(size: 17, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)

            FlowLayout(spacing: 8) {
                ForEach(prompt.chips, id: \.self) { chip in
                    ChipButton(
                        title: chip,
                        isSelected: selectedChip == chip,
                        color: chip == "Skip" ? DreamTheme.moonlight.opacity(0.4) : DreamTheme.lavender
                    ) {
                        if chip == "Skip" {
                            onComplete()
                        } else {
                            selectedChip = chip
                            showNoteField = true
                        }
                    }
                }
            }

            if showNoteField, selectedChip != nil {
                TextField("Add a word or two (optional)", text: $optionalNote)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(DreamTheme.moonlight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DreamTheme.memoryFog.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    saveLifeEntry()
                } label: {
                    Text("Save & continue")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DreamTheme.lavender.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(DreamTheme.moonlight)
                }
                .buttonStyle(.plain)
            }

            if selectedChip == nil {
                Button {
                    onComplete()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 24)
    }

    private func saveLifeEntry() {
        guard let chip = selectedChip, chip != "Skip" else {
            onComplete()
            return
        }

        var tags = [chip]
        if !optionalNote.isEmpty {
            tags.append(optionalNote)
        }

        let entry = LifeEntry(
            content: optionalNote,
            tags: tags,
            linkedDreamID: dream.id,
            promptQuestion: prompt.question
        )
        modelContext.insert(entry)

        if optionalNote.isEmpty {
            dream.lifeEventNote = chip
        } else {
            dream.lifeEventNote = "\(chip): \(optionalNote)"
        }

        try? modelContext.save()
        onComplete()
    }
}
