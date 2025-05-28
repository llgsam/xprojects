import Foundation
import UIKit

/// Defines the different immersive scene types available in the app
enum ImmersiveSceneType: String, CaseIterable, Identifiable {
    case firefly
    // Future scenes will be added here:
    // case starryNight
    // case energyCrystal
    
    var id: String { rawValue }
    
    /// Returns the filename for the background music associated with this scene
    var backgroundMusicFileName: String {
        switch self {
        case .firefly:
            return "firefly_music"
        }
    }
    
    /// Returns the filename for the daytime USDZ model
    var daytimeUSDZ: String {
        switch self {
        case .firefly:
            return "FireflyDaytime"
        }
    }
    
    /// Returns the filename for the nighttime USDZ model
    var nighttimeUSDZ: String {
        switch self {
        case .firefly:
            return "FireflyNighttime"
        }
    }
    
    /// Returns a user-friendly display name for the scene
    var displayName: String {
        switch self {
        case .firefly:
            return "Firefly Dream"
        }
    }
}

/// Represents an emotion script that defines how the scene should change over time
struct EmotionScript: Codable {
    let name: String
    let description: String
    let duration: Double // in seconds
    let keyPoints: [EmotionKeyPoint]
}

/// Represents a key point in an emotion script, defining the emotion intensity and target color at a specific time
struct EmotionKeyPoint: Codable {
    let timeOffset: Double // in seconds from the start
    let emotionIntensity: Double // 0.0-1.0
    let targetColorHex: String
}

// MARK: - UIColor Extension for Hex Support
extension UIColor {
    /// Initialize a UIColor from a hex string (e.g. "#FF0000" for red)
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    /// Convert a UIColor to a hex string
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}
