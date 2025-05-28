import Foundation
import WatchConnectivity

/// Message types that can be sent between iPhone and Apple Watch
enum WatchConnectivityMessageType: String {
    case playPause = "playPause"
    case changeVolume = "changeVolume"
    case switchScene = "switchScene"
    case toggleNightMode = "toggleNightMode"
}

/// Service for handling communication between iPhone and Apple Watch
class WatchConnectivityService: NSObject {
    // MARK: - Singleton
    static let shared = WatchConnectivityService()
    
    // MARK: - Properties
    private var session: WCSession?
    
    // Callback closures for different message types
    var onPlayPauseReceived: (() -> Void)?
    var onVolumeChangeReceived: ((Float) -> Void)?
    var onSceneChangeReceived: ((String) -> Void)?
    var onNightModeToggleReceived: (() -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupSession()
    }
    
    // MARK: - Setup
    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if Watch connectivity is available
    /// - Returns: True if the Watch app is installed and reachable
    func isWatchAppAvailable() -> Bool {
        guard let session = session else { return false }
        #if os(iOS)
        return session.isPaired && session.isWatchAppInstalled
        #else
        return session.isCompanionAppInstalled
        #endif
    }
    
    /// Send a play/pause command to the counterpart device
    func sendPlayPauseCommand() {
        sendMessage([WatchConnectivityMessageType.playPause.rawValue: true])
    }
    
    /// Send a volume change command to the counterpart device
    /// - Parameter volume: The new volume level (0.0 to 1.0)
    func sendVolumeChangeCommand(volume: Float) {
        sendMessage([WatchConnectivityMessageType.changeVolume.rawValue: volume])
    }
    
    /// Send a scene change command to the counterpart device
    /// - Parameter sceneName: The name of the scene to switch to
    func sendSceneChangeCommand(sceneName: String) {
        sendMessage([WatchConnectivityMessageType.switchScene.rawValue: sceneName])
    }
    
    /// Send a night mode toggle command to the counterpart device
    func sendNightModeToggleCommand() {
        sendMessage([WatchConnectivityMessageType.toggleNightMode.rawValue: true])
    }
    
    // MARK: - Private Methods
    
    /// Send a message to the counterpart device
    /// - Parameter message: Dictionary containing the message data
    private func sendMessage(_ message: [String: Any]) {
        guard let session = session, session.activationState == .activated else {
            print("WatchConnectivity session is not active")
            return
        }
        
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        } else {
            session.transferUserInfo(message)
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WatchConnectivity activation failed: \(error.localizedDescription)")
        } else {
            print("WatchConnectivity activated: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleReceivedMessage(userInfo)
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WatchConnectivity session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WatchConnectivity session deactivated")
        // Reactivate the session
        WCSession.default.activate()
    }
    #endif
    
    // MARK: - Message Handling
    
    /// Handle received messages from the counterpart device
    /// - Parameter message: Dictionary containing the message data
    private func handleReceivedMessage(_ message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Handle play/pause command
            if message.keys.contains(WatchConnectivityMessageType.playPause.rawValue) {
                self.onPlayPauseReceived?()
            }
            
            // Handle volume change command
            if let volume = message[WatchConnectivityMessageType.changeVolume.rawValue] as? Float {
                self.onVolumeChangeReceived?(volume)
            }
            
            // Handle scene change command
            if let sceneName = message[WatchConnectivityMessageType.switchScene.rawValue] as? String {
                self.onSceneChangeReceived?(sceneName)
            }
            
            // Handle night mode toggle command
            if message.keys.contains(WatchConnectivityMessageType.toggleNightMode.rawValue) {
                self.onNightModeToggleReceived?()
            }
        }
    }
}
