import SwiftUI
import SwiftData

@main
struct DreamCatcherApp: App {
    @State private var openCaptureOnLaunch = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Dream.self,
            DreamFragment.self,
            DreamSymbol.self,
            DreamPersona.self,
            LifeEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(openCaptureOnLaunch: $openCaptureOnLaunch)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if url.scheme == "dreamcatcher", url.host == "capture" {
                        openCaptureOnLaunch = true
                    }
                }
                .onAppear {
                    SampleDataSeeder.seedIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
