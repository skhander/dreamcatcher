import SwiftUI
import SwiftData

struct ContentView: View {
    @Binding var openCaptureOnLaunch: Bool
    @State private var selectedTab = 0
    @State private var showBedsideCapture = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(showBedsideCapture: $showBedsideCapture)
                .tabItem {
                    Label("Home", systemImage: "cloud.moon.fill")
                }
                .tag(0)

            DreamTimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "sparkles")
                }
                .tag(2)

            PatternsView()
                .tabItem {
                    Label("Patterns", systemImage: "point.3.connected.trianglepath.dotted")
                }
                .tag(3)

            ArchiveView()
                .tabItem {
                    Label("Archive", systemImage: "moon.stars.fill")
                }
                .tag(4)
        }
        .tint(DreamTheme.electricViolet)
        .fullScreenCover(isPresented: $showBedsideCapture) {
            BedsideCaptureView()
        }
        .onAppear {
            if openCaptureOnLaunch {
                showBedsideCapture = true
                openCaptureOnLaunch = false
            } else if UserDefaults.standard.bool(forKey: "shouldOpenCapture") {
                UserDefaults.standard.set(false, forKey: "shouldOpenCapture")
                showBedsideCapture = true
            }
        }
        .onChange(of: openCaptureOnLaunch) { _, newValue in
            if newValue {
                showBedsideCapture = true
                openCaptureOnLaunch = false
            }
        }
    }
}

#Preview {
    ContentView(openCaptureOnLaunch: .constant(false))
        .modelContainer(for: [Dream.self, DreamFragment.self, DreamSymbol.self, DreamPersona.self, LifeEntry.self], inMemory: true)
}
