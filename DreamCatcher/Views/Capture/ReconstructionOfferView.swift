import SwiftUI
import SwiftData

struct ReconstructionOfferView: View {
    let dream: Dream
    let onComplete: () -> Void

    @State private var isProcessing = false
    @State private var showLifeBridge = false
    @State private var lifeBridgeComplete = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            DreamscapeBackground(intensity: .bedside)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    if let narrative = dream.reconstructedNarrative {
                        narrativeSection(narrative)
                    } else if isProcessing {
                        processingSection
                    }

                    if dream.reconstructedNarrative != nil, showLifeBridge, !lifeBridgeComplete {
                        LifeThreadBridgeView(dream: dream) {
                            withAnimation {
                                lifeBridgeComplete = true
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if dream.reconstructedNarrative != nil, lifeBridgeComplete || !showLifeBridge {
                        actionButtons
                    }
                }
                .padding(.vertical, 40)
            }
        }
        .onAppear {
            if dream.reconstructedNarrative == nil {
                isProcessing = true
                Task {
                    await DreamReconstructionService.shared.processDream(dream, context: modelContext)
                    isProcessing = false
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLifeBridge = true
                    }
                }
            } else {
                showLifeBridge = true
            }
        }
    }

    private func narrativeSection(_ narrative: String) -> some View {
        VStack(spacing: 20) {
            Text("Your dream")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(DreamTheme.lavender.opacity(0.8))

            Text(narrative)
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 24)

            if !dream.symbols.isEmpty {
                HStack(spacing: 8) {
                    ForEach(dream.symbols.prefix(5), id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DreamTheme.lavender.opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundStyle(DreamTheme.softGlow)
                    }
                }
            }
        }
    }

    private var processingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(DreamTheme.lavender)
            Text("Putting it together…")
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundStyle(DreamTheme.moonlight.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            NavigationLink {
                DreamDetailView(dream: dream)
            } label: {
                Text("Open dream")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(DreamTheme.lavender.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(DreamTheme.moonlight)
            }

            Button {
                onComplete()
            } label: {
                Text("Later")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(DreamTheme.moonlight.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
    }
}
