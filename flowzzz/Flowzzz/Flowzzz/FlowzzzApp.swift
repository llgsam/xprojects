//
//  FlowzzzApp.swift
//  Flowzzz
//
//  Created by SamDesk on 2025/5/28.
//

import SwiftUI

@main
struct FlowzzzApp: App {
    let persistenceController = PersistenceController.shared
    
    // Initialize services when the app launches
    init() {
        // Pre-load the emotion script
        _ = EmotionScriptService.shared.loadScript(named: "firefly_emotion_script")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
