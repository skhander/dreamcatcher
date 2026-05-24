import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var showBedsideCapture: Bool
    @Query(sort: \Dream.createdAt, order: .reverse) private var dreams: [Dream]
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                DreamscapeBackground(intensity: .standard)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        captureButton
                        if let recent = dreams.first {
                            recentDreamCard(recent)
                        }
                        onThisNightSection
                        quickStats
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(DreamTheme.lavender.opacity(0.7))
                        .padding(16)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(DreamTheme.goldDust.opacity(0.8))
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundStyle(DreamTheme.creamDream.opacity(0.5))
                Image(systemName: "sparkle")
                    .font(.system(size: 6))
                    .foregroundStyle(DreamTheme.creamDream.opacity(0.35))
            }

            Text("Dream Catcher")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(DreamTheme.lavender.opacity(0.8))
                .tracking(3)
                .textCase(.uppercase)
                .padding(.top, 12)

            Text(greeting)
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight)
                .multilineTextAlignment(.center)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "What did you dream?" }
        if hour < 17 { return "Welcome back" }
        return "Good night"
    }

    private var captureButton: some View {
        Button {
            showBedsideCapture = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DreamTheme.electricViolet.opacity(0.12))
                        .frame(width: 120, height: 120)
                        .breathingPulse()

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    DreamTheme.sunsetOrange.opacity(0.35),
                                    DreamTheme.electricViolet.opacity(0.2),
                                    DreamTheme.tealMist.opacity(0.08)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 55
                            )
                        )
                        .frame(width: 88, height: 88)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(DreamTheme.creamDream)
                }

                Text("Record a dream")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(DreamTheme.moonlight)

                Text("Before you forget it")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .glassCard(floating: true)
        }
        .buttonStyle(.plain)
    }

    private func recentDreamCard(_ dream: Dream) -> some View {
        NavigationLink {
            DreamDetailView(dream: dream)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last dream")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender)
                    Spacer()
                    Text(dream.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.5))
                }

                if let narrative = dream.reconstructedNarrative {
                    Text(narrative)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.9))
                        .lineLimit(3)
                } else {
                    Text(dream.rawTranscript)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.9))
                        .lineLimit(3)
                }

                if let emotion = dream.primaryEmotion {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(DreamTheme.emotionColor(emotion))
                            .frame(width: 8, height: 8)
                        Text(emotion.displayName)
                            .font(.caption)
                            .foregroundStyle(DreamTheme.moonlight.opacity(0.7))
                    }
                }
            }
            .padding(20)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var onThisNightSection: some View {
        Group {
            if let pastDream = dreamsOnThisNight.last {
                VStack(alignment: .leading, spacing: 12) {
                    Text("One year ago tonight")
                        .font(.caption)
                        .foregroundStyle(DreamTheme.lavender)

                    Text(pastDream.reconstructedNarrative ?? pastDream.rawTranscript)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(DreamTheme.moonlight.opacity(0.8))
                        .lineLimit(4)
                }
                .padding(20)
                .glassCard()
            }
        }
    }

    private var dreamsOnThisNight: [Dream] {
        let calendar = Calendar.current
        let now = Date()
        return dreams.filter { dream in
            let components = calendar.dateComponents([.month, .day], from: dream.createdAt)
            let nowComponents = calendar.dateComponents([.month, .day], from: now)
            let yearDiff = calendar.component(.year, from: now) - calendar.component(.year, from: dream.createdAt)
            return components.month == nowComponents.month &&
                   components.day == nowComponents.day &&
                   yearDiff >= 1
        }
    }

    private var quickStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("So far")
                .font(.caption)
                .foregroundStyle(DreamTheme.lavender)

            HStack(spacing: 16) {
                statCard(value: "\(dreams.count)", label: dreams.count == 1 ? "Dream" : "Dreams")
                statCard(value: "\(uniqueSymbols.count)", label: uniqueSymbols.count == 1 ? "Symbol" : "Symbols")
            }
        }
    }

    private var uniqueSymbols: Set<String> {
        Set(dreams.flatMap { $0.symbols })
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .light, design: .rounded))
                .foregroundStyle(DreamTheme.moonlight)
            Text(label)
                .font(.caption)
                .foregroundStyle(DreamTheme.moonlight.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }
}
