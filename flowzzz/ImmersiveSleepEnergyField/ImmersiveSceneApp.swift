import SwiftUI

@main
struct ImmersiveSceneApp: App {
    // Initialize services when the app launches
    init() {
        // Pre-load the emotion script
        _ = EmotionScriptService.shared.loadScript(named: "firefly_emotion_script")
        
        // Initialize watch connectivity
        _ = WatchConnectivityService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
