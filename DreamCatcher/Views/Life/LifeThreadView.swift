import SwiftUI
import SwiftData

struct LifeThreadView: View {
    @Query(sort: \LifeEntry.createdAt, order: .reverse) private var lifeEntries: [LifeEntry]
    @Query(sort: \Dream.createdAt, order: .reverse) private var dreams: [Dream]

    @State private var newNote = ""
    @State private var weeklyRecap = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DreamscapeBackground(intensity: .standard)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        weeklyRecapCard
                        addNoteSection
                        timelineSection
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Life")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { refreshRecap() }
            .onChange(of: lifeEntries.count) { _, _ in refreshRecap() }
            .onChange(of: dreams.count) { _, _ in refreshRecap() }
        }
    }

    private var weeklyRecapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundStyle(DreamTheme.lavender)
                Text("This week")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DreamTheme.moonlight)
            }

            Text(weeklyRecap)
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.85))
                .lineSpacing(6)
        }
        .padding(20)
        .glassCard()
    }

    private var addNoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add a note")
                .font(.caption)
                .foregroundStyle(DreamTheme.lavender)

            HStack {
                TextField("What's on your mind?", text: $newNote)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(DreamTheme.moonlight)

                Button {
                    addNote()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(newNote.isEmpty ? DreamTheme.moonlight.opacity(0.3) : DreamTheme.lavender)
                }
                .disabled(newNote.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard()
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                Text("Recent notes")
                    .font(.caption)
                    .foregroundStyle(DreamTheme.lavender)

            if lifeEntries.isEmpty {
                Text("Notes you add will show up here. They help connect dreams to what's going on in your life.")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.5))
                    .padding(20)
                    .glassCard()
            } else {
                ForEach(lifeEntries) { entry in
                    lifeEntryRow(entry)
                }
            }
        }
    }

    private func lifeEntryRow(_ entry: LifeEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(DreamTheme.lavender)
                Spacer()
                if entry.linkedDreamID != nil {
                    Image(systemName: "moon.stars")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.softGlow.opacity(0.7))
                }
            }

            if let question = entry.promptQuestion {
                Text(question)
                    .font(.caption)
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.45))
                    .italic()
            }

            if !entry.content.isEmpty {
                Text(entry.content)
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.9))
            }

            if !entry.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tags.prefix(4), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DreamTheme.lavender.opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundStyle(DreamTheme.softGlow)
                    }
                }
            }

            if let dreamID = entry.linkedDreamID,
               let dream = dreams.first(where: { $0.id == dreamID }) {
                NavigationLink {
                    DreamDetailView(dream: dream)
                } label: {
                    Text(dream.displayTitle)
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender.opacity(0.8))
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    @Environment(\.modelContext) private var modelContext

    private func addNote() {
        let text = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let entry = LifeEntry(content: text)
        modelContext.insert(entry)
        try? modelContext.save()
        newNote = ""
        refreshRecap()
    }

    private func refreshRecap() {
        weeklyRecap = LifeRecapService.weeklyRecap(dreams: dreams, lifeEntries: lifeEntries)
    }
}
