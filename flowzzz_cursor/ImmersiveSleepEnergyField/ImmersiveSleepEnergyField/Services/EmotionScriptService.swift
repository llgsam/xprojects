import Foundation
import UIKit

class EmotionScriptService: ObservableObject {
    static let shared = EmotionScriptService()
    
    @Published var currentEmotionIntensity: Float = 0.5
    @Published var currentTargetColor: UIColor = UIColor(hex: "#FFD700") ?? .yellow
    
    private var emotionScript: EmotionScript?
    private var scriptStartTime: Date?
    
    private init() {}
    
    // MARK: - Script Loading
    func loadScript(named filename: String, fileExtension: String = "json") -> Bool {
        // First try to load from bundle
        if let url = Bundle.main.url(forResource: filename, withExtension: fileExtension),
           let data = try? Data(contentsOf: url) {
            return parseScript(from: data)
        }
        
        // If not found in bundle, use sample data
        print("Script file not found in bundle, using sample data for: \(filename).\(fileExtension)")
        return loadSampleScript()
    }
    
    private func parseScript(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            emotionScript = try decoder.decode(EmotionScript.self, from: data)
            scriptStartTime = Date()
            return true
        } catch {
            print("Failed to parse emotion script: \(error)")
            return loadSampleScript()
        }
    }
    
    private func loadSampleScript() -> Bool {
        let sampleJSON = """
        {
            "duration": 300.0,
            "key_points": [
                {
                    "timestamp": 0.0,
                    "emotion_intensity": 0.8,
                    "target_color_hex": "#FF6B6B"
                },
                {
                    "timestamp": 30.0,
                    "emotion_intensity": 0.6,
                    "target_color_hex": "#4ECDC4"
                },
                {
                    "timestamp": 60.0,
                    "emotion_intensity": 0.4,
                    "target_color_hex": "#45B7D1"
                },
                {
                    "timestamp": 120.0,
                    "emotion_intensity": 0.3,
                    "target_color_hex": "#96CEB4"
                },
                {
                    "timestamp": 180.0,
                    "emotion_intensity": 0.2,
                    "target_color_hex": "#FFEAA7"
                },
                {
                    "timestamp": 240.0,
                    "emotion_intensity": 0.15,
                    "target_color_hex": "#DDA0DD"
                },
                {
                    "timestamp": 300.0,
                    "emotion_intensity": 0.1,
                    "target_color_hex": "#E6E6FA"
                }
            ]
        }
        """
        
        guard let data = sampleJSON.data(using: .utf8) else { return false }
        return parseScript(from: data)
    }
    
    // MARK: - Script Playback Control
    func startScript() {
        scriptStartTime = Date()
    }
    
    func stopScript() {
        scriptStartTime = nil
    }
    
    func resetScript() {
        scriptStartTime = Date()
    }
    
    // MARK: - Current Values Calculation
    func getCurrentEmotionIntensity(at currentTime: TimeInterval? = nil) -> Float {
        guard let script = emotionScript else { return 0.5 }
        
        let time = currentTime ?? getCurrentScriptTime()
        return interpolateEmotionIntensity(at: time, keyPoints: script.keyPoints)
    }
    
    func getCurrentTargetColor(at currentTime: TimeInterval? = nil) -> UIColor {
        guard let script = emotionScript else { return UIColor(hex: "#FFD700") ?? .yellow }
        
        let time = currentTime ?? getCurrentScriptTime()
        return interpolateColor(at: time, keyPoints: script.keyPoints)
    }
    
    func getScriptDuration() -> TimeInterval {
        return emotionScript?.duration ?? 300.0
    }
    
    private func getCurrentScriptTime() -> TimeInterval {
        guard let startTime = scriptStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        let duration = getScriptDuration()
        
        // Loop the script
        return elapsed.truncatingRemainder(dividingBy: duration)
    }
    
    // MARK: - Interpolation Methods
    private func interpolateEmotionIntensity(at time: TimeInterval, keyPoints: [EmotionKeyPoint]) -> Float {
        guard !keyPoints.isEmpty else { return 0.5 }
        
        // Find the two keypoints to interpolate between
        let sortedPoints = keyPoints.sorted { $0.timestamp < $1.timestamp }
        
        // If time is before first point
        if time <= sortedPoints.first!.timestamp {
            return sortedPoints.first!.emotionIntensity
        }
        
        // If time is after last point
        if time >= sortedPoints.last!.timestamp {
            return sortedPoints.last!.emotionIntensity
        }
        
        // Find the two points to interpolate between
        for i in 0..<(sortedPoints.count - 1) {
            let currentPoint = sortedPoints[i]
            let nextPoint = sortedPoints[i + 1]
            
            if time >= currentPoint.timestamp && time <= nextPoint.timestamp {
                let progress = (time - currentPoint.timestamp) / (nextPoint.timestamp - currentPoint.timestamp)
                let interpolatedValue = currentPoint.emotionIntensity + Float(progress) * (nextPoint.emotionIntensity - currentPoint.emotionIntensity)
                return interpolatedValue
            }
        }
        
        return sortedPoints.last!.emotionIntensity
    }
    
    private func interpolateColor(at time: TimeInterval, keyPoints: [EmotionKeyPoint]) -> UIColor {
        guard !keyPoints.isEmpty else { return UIColor(hex: "#FFD700") ?? .yellow }
        
        let sortedPoints = keyPoints.sorted { $0.timestamp < $1.timestamp }
        
        // If time is before first point
        if time <= sortedPoints.first!.timestamp {
            return UIColor(hex: sortedPoints.first!.targetColorHex) ?? .yellow
        }
        
        // If time is after last point
        if time >= sortedPoints.last!.timestamp {
            return UIColor(hex: sortedPoints.last!.targetColorHex) ?? .yellow
        }
        
        // Find the two points to interpolate between
        for i in 0..<(sortedPoints.count - 1) {
            let currentPoint = sortedPoints[i]
            let nextPoint = sortedPoints[i + 1]
            
            if time >= currentPoint.timestamp && time <= nextPoint.timestamp {
                let progress = (time - currentPoint.timestamp) / (nextPoint.timestamp - currentPoint.timestamp)
                
                guard let currentColor = UIColor(hex: currentPoint.targetColorHex),
                      let nextColor = UIColor(hex: nextPoint.targetColorHex) else {
                    return UIColor(hex: currentPoint.targetColorHex) ?? .yellow
                }
                
                return interpolateUIColor(from: currentColor, to: nextColor, progress: CGFloat(progress))
            }
        }
        
        return UIColor(hex: sortedPoints.last!.targetColorHex) ?? .yellow
    }
    
    private func interpolateUIColor(from startColor: UIColor, to endColor: UIColor, progress: CGFloat) -> UIColor {
        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0
        
        startColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        endColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)
        
        let red = startRed + (endRed - startRed) * progress
        let green = startGreen + (endGreen - startGreen) * progress
        let blue = startBlue + (endBlue - startBlue) * progress
        let alpha = startAlpha + (endAlpha - startAlpha) * progress
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // MARK: - Update Current Values
    func updateCurrentValues() {
        currentEmotionIntensity = getCurrentEmotionIntensity()
        currentTargetColor = getCurrentTargetColor()
    }
} 