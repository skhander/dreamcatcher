import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lens = AppSettings.interpretationLens
    @State private var showJungian = AppSettings.showJungianSymbolic

    var body: some View {
        NavigationStack {
            ZStack {
                DreamscapeBackground(intensity: .standard)
                    .ignoresSafeArea()

                Form {
                    Section {
                        Picker("Primary lens", selection: $lens) {
                            ForEach(InterpretationLens.allCases) { option in
                                Label(option.rawValue, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                        .listRowBackground(DreamTheme.memoryFog.opacity(0.4))

                        Toggle("Show Jungian & Symbolic layer", isOn: $showJungian)
                            .listRowBackground(DreamTheme.memoryFog.opacity(0.4))
                    } header: {
                        Text("Interpretation")
                    } footer: {
                        Text("Islamic Reflection uses ru'ya, hulum, and adghath framing. Reflective guidance only, not religious rulings.")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            labelRow(title: "Ru'ya", detail: "Comforting or meaningful dreams — sit with gratitude")
                            labelRow(title: "Hulum", detail: "Disturbing dreams — seek refuge, don't dwell")
                            labelRow(title: "Adghath", detail: "Mixed fragments from daily thought")
                        }
                        .listRowBackground(DreamTheme.memoryFog.opacity(0.4))
                    } header: {
                        Text("Islamic dream categories")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        AppSettings.interpretationLens = lens
                        AppSettings.showJungianSymbolic = showJungian
                        dismiss()
                    }
                    .foregroundStyle(DreamTheme.lavender)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func labelRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DreamTheme.moonlight)
            Text(detail)
                .font(.caption)
                .foregroundStyle(DreamTheme.moonlight.opacity(0.55))
        }
        .padding(.vertical, 4)
    }
}
