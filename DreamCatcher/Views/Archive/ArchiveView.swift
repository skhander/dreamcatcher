import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dream.createdAt, order: .reverse) private var dreams: [Dream]
    @Query private var lifeEntries: [LifeEntry]
    @State private var searchText = ""

    private var filteredDreams: [Dream] {
        if searchText.isEmpty { return dreams }
        let query = searchText.lowercased()
        return dreams.filter { dream in
            dream.rawTranscript.lowercased().contains(query) ||
            (dream.reconstructedNarrative?.lowercased().contains(query) ?? false) ||
            dream.symbols.contains(where: { $0.contains(query) }) ||
            dream.emotions.contains(where: { $0.contains(query) })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DreamscapeBackground(intensity: .standard)
                    .ignoresSafeArea()

                if dreams.isEmpty {
                    emptyState
                } else {
                    dreamList
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search dreams")
            .navigationDestination(for: UUID.self) { dreamID in
                if let dream = dreams.first(where: { $0.id == dreamID }) {
                    DreamDetailView(dream: dream)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars")
                .font(.system(size: 40))
                .foregroundStyle(DreamTheme.goldDust.opacity(0.5))
            Text("No dreams yet")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
            Text("Dreams you save will show up here")
                .font(.caption)
                .foregroundStyle(DreamTheme.moonlight.opacity(0.4))
        }
    }

    private var dreamList: some View {
        List {
            ForEach(filteredDreams) { dream in
                NavigationLink(value: dream.id) {
                    DreamRowView(dream: dream)
                }
                .listRowBackground(DreamTheme.memoryFog.opacity(0.3))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        DreamDeletionService.delete(dream, context: modelContext, lifeEntries: lifeEntries)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
}

struct DreamRowView: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dream.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(DreamTheme.lavender)
                Spacer()
                if let emotion = dream.primaryEmotion {
                    Circle()
                        .fill(DreamTheme.emotionColor(emotion))
                        .frame(width: 8, height: 8)
                }
            }

            Text(dream.reconstructedNarrative ?? dream.rawTranscript)
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.85))
                .lineLimit(2)

            if !dream.symbols.isEmpty {
                HStack(spacing: 6) {
                    ForEach(dream.symbols.prefix(3), id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DreamTheme.lavender.opacity(0.15))
                            .clipShape(Capsule())
                            .foregroundStyle(DreamTheme.softGlow.opacity(0.8))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
