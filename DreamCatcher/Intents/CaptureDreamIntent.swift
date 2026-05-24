import AppIntents
import Foundation

struct CaptureDreamIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Dream"
    static var description = IntentDescription("Open Dream Catcher to capture a dream fragment.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "shouldOpenCapture")
        return .result()
    }
}

struct DreamCatcherShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureDreamIntent(),
            phrases: [
                "Capture my dream in \(.applicationName)",
                "Log my dream in \(.applicationName)",
                "Record my dream in \(.applicationName)"
            ],
            shortTitle: "Capture Dream",
            systemImageName: "moon.stars.fill"
        )
    }
}
