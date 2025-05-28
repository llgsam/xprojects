import Foundation
import UIKit

// MARK: - Scene Type Definition
enum ImmersiveSceneType: String, CaseIterable {
    case firefly = "firefly"
    
    var displayName: String {
        switch self {
        case .firefly:
            return "萤火虫之梦"
        }
    }
    
    var backgroundMusicFileName: String {
        switch self {
        case .firefly:
            return "firefly_music"
        }
    }
    
    var daytimeUSDZ: String {
        switch self {
        case .firefly:
            return "FireflyDaytime"
        }
    }
    
    var nighttimeUSDZ: String {
        switch self {
        case .firefly:
            return "FireflyNighttime"
        }
    }
    
    var emotionScriptFileName: String {
        switch self {
        case .firefly:
            return "firefly_emotion_script"
        }
    }
}

// MARK: - Emotion Script Data Structures
struct EmotionScript: Codable {
    let duration: TimeInterval
    let keyPoints: [EmotionKeyPoint]
    
    enum CodingKeys: String, CodingKey {
        case duration
        case keyPoints = "key_points"
    }
}

struct EmotionKeyPoint: Codable {
    let timestamp: TimeInterval
    let emotionIntensity: Float
    let targetColorHex: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case emotionIntensity = "emotion_intensity"
        case targetColorHex = "target_color_hex"
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    a = 1.0
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
    
    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
    }
}

// MARK: - Scene Configuration
struct SceneConfiguration {
    let sceneType: ImmersiveSceneType
    let isNightMode: Bool
    let emotionScript: EmotionScript?
    
    init(sceneType: ImmersiveSceneType, isNightMode: Bool, emotionScript: EmotionScript? = nil) {
        self.sceneType = sceneType
        self.isNightMode = isNightMode
        self.emotionScript = emotionScript
    }
} 