import SwiftUI

@main
struct ImmersiveSleepEnergyFieldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initialize services
                    _ = MusicService.shared
                    _ = EmotionScriptService.shared
                    _ = WatchConnectivityService.shared
                }
        }
    }
} 