import Foundation
import UIKit

/// Service for loading and managing emotion scripts that drive the dynamic scene behavior
class EmotionScriptService {
    // MARK: - Singleton
    static let shared = EmotionScriptService()
    private init() {}
    
    // MARK: - Properties
    private var currentScript: EmotionScript?
    private var startTime: Date?
    
    // MARK: - Public Methods
    
    /// Load an emotion script from a JSON file in the app bundle
    /// - Parameters:
    ///   - named: The name of the script file
    ///   - fileExtension: The extension of the file (default: "json")
    /// - Returns: True if the script was loaded successfully, false otherwise
    @discardableResult
    func loadScript(named filename: String, fileExtension: String = "json") -> Bool {
        // Use the default embedded script immediately to avoid file I/O during startup
        if filename == "firefly_emotion_script" {
            // Use the default script first for immediate response
            do {
                let decoder = JSONDecoder()
                currentScript = try decoder.decode(EmotionScript.self, from: defaultFireflyEmotionScript.data(using: .utf8)!)
                startTime = Date()
                
                // Then try to load from bundle in background if available
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    if let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) {
                        do {
                            let data = try Data(contentsOf: url)
                            let decoder = JSONDecoder()
                            let loadedScript = try decoder.decode(EmotionScript.self, from: data)
                            
                            // Update on main thread
                            DispatchQueue.main.async {
                                self?.currentScript = loadedScript
                                print("[DEBUG] 情绪脚本从文件更新完成")
                            }
                        } catch {
                            print("[DEBUG] 使用默认脚本: \(error.localizedDescription)")
                        }
                    }
                }
                
                return true
            } catch {
                print("Error loading default script: \(error.localizedDescription)")
            }
        } else {
            // For non-default scripts, try loading from bundle
            if let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    currentScript = try decoder.decode(EmotionScript.self, from: data)
                    startTime = Date()
                    return true
                } catch {
                    print("Error loading script from file: \(error.localizedDescription)")
                }
            }
        }
        
        return false
    }
    
    /// Reset the script playback to the beginning
    func resetScript() {
        startTime = Date()
    }
    
    /// Get the current emotion intensity based on the elapsed time
    /// - Parameter time: Optional time to use instead of the elapsed time since start
    /// - Returns: Emotion intensity value between 0.0 and 1.0
    func getCurrentEmotionIntensity(at time: TimeInterval? = nil) -> Double {
        guard let script = currentScript, let startTime = startTime else { return 0.5 }
        
        let elapsedTime = time ?? -startTime.timeIntervalSinceNow
        return getInterpolatedValue(for: elapsedTime, valueSelector: { $0.emotionIntensity })
    }
    
    /// Get the current target color based on the elapsed time
    /// - Parameter time: Optional time to use instead of the elapsed time since start
    /// - Returns: UIColor representing the current target color
    func getCurrentTargetColor(at time: TimeInterval? = nil) -> UIColor {
        guard let script = currentScript, let startTime = startTime else { 
            return UIColor(hex: "#5D88F0") // Default blue color
        }
        
        let elapsedTime = time ?? -startTime.timeIntervalSinceNow
        
        // Find the two keypoints to interpolate between
        guard let (prevKeyPoint, nextKeyPoint, progress) = getInterpolationPoints(for: elapsedTime) else {
            // If we can't find keypoints, return the color of the last keypoint
            if let lastKeyPoint = script.keyPoints.last {
                return UIColor(hex: lastKeyPoint.targetColorHex)
            }
            return UIColor(hex: "#5D88F0") // Default blue color
        }
        
        // Interpolate between the two colors
        let prevColor = UIColor(hex: prevKeyPoint.targetColorHex)
        let nextColor = UIColor(hex: nextKeyPoint.targetColorHex)
        
        return interpolateColor(from: prevColor, to: nextColor, progress: progress)
    }
    
    /// Get the total duration of the current script
    /// - Returns: Duration in seconds
    func getScriptDuration() -> TimeInterval {
        return currentScript?.duration ?? 0
    }
    
    /// Get the elapsed time since the script started
    /// - Returns: Elapsed time in seconds
    func getElapsedTime() -> TimeInterval {
        guard let startTime = startTime else { return 0 }
        return -startTime.timeIntervalSinceNow
    }
    
    // MARK: - Private Methods
    
    /// Helper method to get interpolated values from the emotion script
    private func getInterpolatedValue<T: BinaryFloatingPoint>(for time: TimeInterval, valueSelector: (EmotionKeyPoint) -> T) -> T {
        guard let (prevKeyPoint, nextKeyPoint, progress) = getInterpolationPoints(for: time) else {
            // If we can't find keypoints, return the value of the last keypoint
            if let lastKeyPoint = currentScript?.keyPoints.last {
                return valueSelector(lastKeyPoint)
            }
            return 0.5 as! T // Default value
        }
        
        let prevValue = valueSelector(prevKeyPoint)
        let nextValue = valueSelector(nextKeyPoint)
        
        return prevValue + T(progress) * (nextValue - prevValue)
    }
    
    /// Helper method to find the two keypoints to interpolate between for a given time
    private func getInterpolationPoints(for time: TimeInterval) -> (prev: EmotionKeyPoint, next: EmotionKeyPoint, progress: Double)? {
        guard let script = currentScript, !script.keyPoints.isEmpty else { return nil }
        
        // Loop the script if we've reached the end
        let loopedTime = time.truncatingRemainder(dividingBy: script.duration)
        
        // Find the two keypoints to interpolate between
        var prevKeyPoint: EmotionKeyPoint?
        var nextKeyPoint: EmotionKeyPoint?
        
        for keyPoint in script.keyPoints {
            if keyPoint.timeOffset <= loopedTime {
                prevKeyPoint = keyPoint
            } else {
                nextKeyPoint = keyPoint
                break
            }
        }
        
        // Handle edge cases
        if prevKeyPoint == nil {
            // If we're before the first keypoint
            prevKeyPoint = script.keyPoints.last
            nextKeyPoint = script.keyPoints.first
        } else if nextKeyPoint == nil {
            // If we're after the last keypoint
            nextKeyPoint = script.keyPoints.first
        }
        
        guard let prev = prevKeyPoint, let next = nextKeyPoint else { return nil }
        
        // Calculate progress between the two keypoints
        let prevTime = prev.timeOffset
        let nextTime = next.timeOffset > prevTime ? next.timeOffset : next.timeOffset + script.duration
        let progress = (loopedTime - prevTime) / (nextTime - prevTime)
        
        return (prev, next, progress)
    }
    
    /// Helper method to interpolate between two colors
    private func interpolateColor(from: UIColor, to: UIColor, progress: Double) -> UIColor {
        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0
        
        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0
        
        from.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        to.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
        
        let red = fromRed + CGFloat(progress) * (toRed - fromRed)
        let green = fromGreen + CGFloat(progress) * (toGreen - fromGreen)
        let blue = fromBlue + CGFloat(progress) * (toBlue - fromBlue)
        let alpha = fromAlpha + CGFloat(progress) * (toAlpha - fromAlpha)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - Default Emotion Script
private let defaultFireflyEmotionScript = """
{
    "name": "Firefly Dream",
    "description": "A calming journey through a firefly-filled forest, transitioning from excitement to peaceful slumber",
    "duration": 600,
    "keyPoints": [
        {
            "timeOffset": 0,
            "emotionIntensity": 0.3,
            "targetColorHex": "#5D88F0"
        },
        {
            "timeOffset": 60,
            "emotionIntensity": 0.5,
            "targetColorHex": "#7A9DF5"
        },
        {
            "timeOffset": 120,
            "emotionIntensity": 0.7,
            "targetColorHex": "#97B2FA"
        },
        {
            "timeOffset": 180,
            "emotionIntensity": 0.8,
            "targetColorHex": "#B4C7FF"
        },
        {
            "timeOffset": 240,
            "emotionIntensity": 0.9,
            "targetColorHex": "#D1DCFF"
        },
        {
            "timeOffset": 300,
            "emotionIntensity": 0.8,
            "targetColorHex": "#C3E8FF"
        },
        {
            "timeOffset": 360,
            "emotionIntensity": 0.7,
            "targetColorHex": "#A0E5FF"
        },
        {
            "timeOffset": 420,
            "emotionIntensity": 0.6,
            "targetColorHex": "#7DDAFF"
        },
        {
            "timeOffset": 480,
            "emotionIntensity": 0.4,
            "targetColorHex": "#5AC9F5"
        },
        {
            "timeOffset": 540,
            "emotionIntensity": 0.2,
            "targetColorHex": "#3BBAEB"
        }
    ]
}
"""
