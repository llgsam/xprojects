import Foundation
import WatchConnectivity

class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isWatchConnected: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity is not supported on this device")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    // MARK: - Send Messages to Watch
    func sendPlayPauseCommand() {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        let message = ["command": "playPause"]
        WCSession.default.sendMessage(message, replyHandler: { response in
            print("Watch responded: \(response)")
        }) { error in
            print("Failed to send message to watch: \(error)")
        }
    }
    
    func sendVolumeUpdate(_ volume: Float) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        let message = ["command": "volumeUpdate", "volume": volume] as [String : Any]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send volume update to watch: \(error)")
        }
    }
    
    func sendSceneUpdate(_ sceneType: ImmersiveSceneType, isNightMode: Bool) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        let message = [
            "command": "sceneUpdate",
            "sceneType": sceneType.rawValue,
            "isNightMode": isNightMode
        ] as [String : Any]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send scene update to watch: \(error)")
        }
    }
    
    // MARK: - Context Updates
    func updateApplicationContext() {
        guard WCSession.default.activationState == .activated else { return }
        
        let context = [
            "isPlaying": MusicService.shared.isPlaying,
            "volume": MusicService.shared.volume,
            "currentScene": "firefly" // TODO: Get from SceneViewModel
        ] as [String : Any]
        
        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            
            if let error = error {
                print("WCSession activation failed: \(error)")
            } else {
                print("WCSession activated with state: \(activationState.rawValue)")
                self.isWatchAppInstalled = session.isWatchAppInstalled
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        DispatchQueue.main.async {
            self.isWatchConnected = false
        }
        
        // Reactivate the session for iOS
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.activationState == .activated
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    // MARK: - Receive Messages from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Received message from watch: \(message)")
        
        guard let command = message["command"] as? String else {
            replyHandler(["error": "Invalid command"])
            return
        }
        
        DispatchQueue.main.async {
            switch command {
            case "playPause":
                self.handlePlayPauseFromWatch()
                replyHandler(["status": "success"])
                
            case "volumeUp":
                self.handleVolumeUpFromWatch()
                replyHandler(["status": "success"])
                
            case "volumeDown":
                self.handleVolumeDownFromWatch()
                replyHandler(["status": "success"])
                
            case "toggleNightMode":
                self.handleToggleNightModeFromWatch()
                replyHandler(["status": "success"])
                
            default:
                replyHandler(["error": "Unknown command"])
            }
        }
    }
    
    // MARK: - Handle Watch Commands
    private func handlePlayPauseFromWatch() {
        let musicService = MusicService.shared
        if musicService.isPlaying {
            musicService.pause()
        } else {
            musicService.resume()
        }
    }
    
    private func handleVolumeUpFromWatch() {
        let musicService = MusicService.shared
        let newVolume = min(1.0, musicService.volume + 0.1)
        musicService.setVolume(newVolume)
    }
    
    private func handleVolumeDownFromWatch() {
        let musicService = MusicService.shared
        let newVolume = max(0.0, musicService.volume - 0.1)
        musicService.setVolume(newVolume)
    }
    
    private func handleToggleNightModeFromWatch() {
        // TODO: Implement when SceneViewModel is available
        print("Toggle night mode requested from watch")
    }
} 