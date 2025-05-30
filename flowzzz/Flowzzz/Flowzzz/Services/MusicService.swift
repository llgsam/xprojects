import Foundation
import AVFoundation

/// Service for handling background music playback and audio analysis
class MusicService: NSObject {
    // MARK: - Singleton
    static let shared = MusicService()
    private override init() {}
    
    // MARK: - Properties
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    
    // Current playback state
    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    
    // MARK: - Public Methods
    
    /// Play music from the specified file
    /// - Parameters:
    ///   - filename: The name of the audio file
    ///   - fileExtension: The extension of the audio file (default: "mp3")
    /// - Returns: True if playback started successfully, false otherwise
    @discardableResult
    func playMusic(filename: String, fileExtension: String = "mp3") -> Bool {
        // Check if we already have a prepared player
        if let player = audioPlayer {
            // Start playback of already prepared audio
            player.play()
            isPlaying = true
            return true
        }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("Error: Could not find audio file \(filename).\(fileExtension)")
            return false
        }
        
        // First set a loading flag
        isLoading = true
        
        do {
            // Set up audio session first (this is quick)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create the player but defer heavy operations
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            
            // Prepare to play in background
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.audioPlayer?.prepareToPlay()
                
                DispatchQueue.main.async {
                    if let player = self?.audioPlayer {
                        // Start playback
                        player.play()
                        self?.isPlaying = true
                        self?.duration = player.duration
                        self?.isLoading = false
                        print("[DEBUG] 音乐播放准备完成并开始播放")
                    }
                }
            }
            
            return true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    /// Pause the currently playing music
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    /// Resume playback if paused
    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }
    
    /// Toggle between play and pause
    @discardableResult
    func togglePlayback() -> Bool {
        if isPlaying {
            pause()
            return false
        } else {
            if audioPlayer != nil {
                resume()
                return true
            } else {
                return false
            }
        }
    }
    
    /// Set the volume of the audio player
    /// - Parameter volume: Volume level (0.0 to 1.0)
    func setVolume(volume: Float) {
        audioPlayer?.volume = volume
    }
    
    /// Get the current playback position
    /// - Returns: Current time in seconds
    func getCurrentTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    /// Get the total duration of the current audio
    /// - Returns: Duration in seconds
    func getDuration() -> TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    /// Seek to a specific position in the audio
    /// - Parameter time: Target time in seconds
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = min(max(0, time), audioPlayer?.duration ?? 0)
    }
    
    /// Get the average power level of the current audio
    /// - Returns: A value between 0.0 and 1.0 representing the audio power
    func getAveragePower() -> Float {
        // In a real implementation, this would analyze the audio in real-time
        // For now, we'll return a simulated value based on a sine wave
        
        // Create a pulsing effect with period of about 3 seconds
        let time = Date().timeIntervalSince1970
        let value = (sin(time * 2.0) + 1.0) / 2.0
        
        return Float(value)
    }
}

// MARK: - AVAudioPlayerDelegate
extension MusicService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
