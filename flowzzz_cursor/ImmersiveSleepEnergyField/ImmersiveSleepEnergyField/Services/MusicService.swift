import Foundation
import AVFoundation

class MusicService: ObservableObject {
    static let shared = MusicService()
    
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.7
    
    private var audioPlayer: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    
    private init() {
        setupAudioSession()
    }
    
    deinit {
        stopDisplayLink()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Music Playback Control
    func playMusic(filename: String, fileExtension: String = "mp3") {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("Could not find audio file: \(filename).\(fileExtension)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaying = true
            duration = audioPlayer?.duration ?? 0
            
            startDisplayLink()
        } catch {
            print("Error playing audio: \(error)")
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopDisplayLink()
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startDisplayLink()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        stopDisplayLink()
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        audioPlayer?.volume = volume
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // MARK: - Audio Analysis (Simulated for now)
    func getAveragePower() -> Float {
        // TODO: Implement real-time audio analysis
        // For now, return a simulated value based on sine wave
        let time = Date().timeIntervalSince1970
        let simulatedPower = Float(sin(time * 2.0) * 0.5 + 0.5) // 0.0 to 1.0
        return simulatedPower
    }
    
    func getFrequencyData() -> [Float] {
        // TODO: Implement FFT analysis for frequency data
        // For now, return simulated frequency bands
        return (0..<8).map { _ in Float.random(in: 0.0...1.0) }
    }
    
    // MARK: - Display Link for Time Updates
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(updateTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateTime() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
    }
}

// MARK: - AVAudioPlayerDelegate
extension MusicService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            isPlaying = false
            currentTime = 0
            stopDisplayLink()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
        isPlaying = false
        stopDisplayLink()
    }
} 