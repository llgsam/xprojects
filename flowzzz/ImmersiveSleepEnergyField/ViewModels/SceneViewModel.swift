import Foundation
import UIKit
import RealityKit
import Combine
import QuartzCore

/// ViewModel that manages the immersive scene state and coordinates between services
class SceneViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedScene: ImmersiveSceneType = .firefly
    @Published var isNightMode: Bool
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.8
    @Published var sceneBrightness: Double = 0.5
    
    // Properties to help manage updates
    @Published var isEditingBrightness: Bool = false
    private var lastBrightnessUpdateTime: TimeInterval = 0
    private var isUpdatingScene: Bool = false
    private var updateQueue = DispatchQueue(label: "com.flowzzz.sceneUpdateQueue", qos: .userInteractive)
    
    // Debug mode
    @Published var showDebugInfo: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var displayLink: CADisplayLink?
    private var sceneAnchor: AnchorEntity?
    private var particleEmitters: [ParticleEmitter] = []
    private var lastUpdateTime: TimeInterval = 0
    private var hapticFeedbackDisabled: Bool = true // Disable haptic feedback by default
    
    // MARK: - Initialization
    init() {
        // Set initial night mode based on current time
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        isNightMode = hour < 6 || hour >= 18
        
        // Set up services
        setupServices()
    }
    
    // MARK: - Public Methods
    
    /// Load the initial scene into the provided ARView
    /// - Parameter arView: The ARView to load the scene into
    func loadInitialScene(into arView: ARView) {
        loadScene(type: selectedScene, isNightMode: isNightMode, into: arView)
        setupDynamicDrivers()
    }
    
    /// Select a new scene type
    /// - Parameter sceneType: The scene type to select
    func selectScene(_ sceneType: ImmersiveSceneType) {
        // Currently only firefly scene is supported
        if sceneType == .firefly {
            selectedScene = sceneType
        }
    }
    
    /// Unload the current scene from the provided ARView
    /// - Parameter arView: The ARView to unload the scene from
    func unloadCurrentScene(from arView: ARView) {
        if let anchor = sceneAnchor {
            arView.scene.removeAnchor(anchor)
            sceneAnchor = nil
        }
        particleEmitters.removeAll()
    }
    
    /// Load a scene into the provided ARView
    /// - Parameters:
    ///   - type: The type of scene to load
    ///   - isNightMode: Whether to load the night mode version of the scene
    ///   - arView: The ARView to load the scene into
    func loadScene(type: ImmersiveSceneType, isNightMode: Bool, into arView: ARView) {
        // Unload any existing scene
        unloadCurrentScene(from: arView)
        
        // Create a new anchor for the scene
        sceneAnchor = AnchorEntity(world: [0, 0, -2])
        
        // Configure the scene based on the type
        switch type {
        case .firefly:
            configureFireflyScene(for: sceneAnchor!, isNight: isNightMode)
        }
        
        // Add the anchor to the scene
        if let anchor = sceneAnchor {
            arView.scene.addAnchor(anchor)
        }
        
        // Start the music
        playMusic()
    }
    
    /// Play or pause the background music
    func togglePlayback() {
        isPlaying = MusicService.shared.togglePlayback()
    }
    
    /// Set the volume of the background music
    /// - Parameter newVolume: The new volume level (0.0 to 1.0)
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        MusicService.shared.setVolume(volume: newVolume)
    }
    
    /// Toggle between day and night mode
    func toggleNightMode() {
        isNightMode.toggle()
    }
    
    /// Determines if the brightness should be updated based on timing and current state
    /// This helps reduce the frequency of updates during sliding to minimize haptic feedback issues and prevent freezing
    func shouldUpdateBrightness() -> Bool {
        // If already updating, don't allow another update
        if isUpdatingScene {
            return false
        }
        
        // If not actively editing, always allow updates
        if !isEditingBrightness {
            return true
        }
        
        // During active editing, only update every 200ms to reduce update frequency
        let currentTime = CACurrentMediaTime()
        if currentTime - lastBrightnessUpdateTime > 0.2 { // 200ms interval (increased from 100ms)
            lastBrightnessUpdateTime = currentTime
            return true
        }
        
        return false
    }
    
    /// Update the scene brightness without reloading the entire scene
    /// This method uses a background queue to avoid blocking the UI
    func updateSceneBrightness() {
        // Set flag to prevent concurrent updates
        if isUpdatingScene {
            return
        }
        
        isUpdatingScene = true
        
        // Use a background queue for the update
        updateQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Capture current brightness value to avoid race conditions
            let brightness = self.sceneBrightness
            
            // Update light intensity in the scene based on brightness value
            if let anchor = self.sceneAnchor {
                for child in anchor.children {
                    if let lightEntity = child.children.first(where: { $0.components[PointLightComponent.self] != nil }) {
                        if var light = lightEntity.components[PointLightComponent.self] {
                            // Scale the base intensity by the brightness factor
                            let baseIntensity: Float = 500.0
                            light.intensity = baseIntensity * Float(brightness * 2.0)
                            lightEntity.components[PointLightComponent.self] = light
                        }
                    }
                }
            }
            
            // Update particle emitter properties based on brightness
            for emitter in self.particleEmitters {
                // Adjust particle birth rate based on brightness
                let baseBirthRate: Float = self.isNightMode ? 5.0 : 1.0
                emitter.mainEmitter.birthRate = baseBirthRate * Float(brightness * 2.0)
                
                // Adjust particle size based on brightness
                let baseSize: Float = 0.02
                let sizeFactor = 0.5 + Float(brightness)
                emitter.mainEmitter.particleSize = [baseSize * sizeFactor, baseSize * sizeFactor, baseSize * sizeFactor]
            }
            
            // Reset update flag on main thread
            DispatchQueue.main.async {
                self.isUpdatingScene = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Set up services and observers
    private func setupServices() {
        // Load the emotion script
        EmotionScriptService.shared.loadScript(named: "firefly_emotion_script")
        
        // Set up watch connectivity
        setupWatchConnectivity()
    }
    
    /// Set up watch connectivity service
    private func setupWatchConnectivity() {
        let watchService = WatchConnectivityService.shared
        
        watchService.onPlayPauseReceived = { [weak self] in
            self?.togglePlayback()
        }
        
        watchService.onVolumeChangeReceived = { [weak self] volume in
            self?.setVolume(volume)
        }
        
        watchService.onSceneChangeReceived = { [weak self] sceneName in
            if let sceneType = ImmersiveSceneType(rawValue: sceneName) {
                self?.selectScene(sceneType)
            }
        }
        
        watchService.onNightModeToggleReceived = { [weak self] in
            self?.toggleNightMode()
        }
    }
    
    /// Configure the firefly scene
    /// - Parameters:
    ///   - anchor: The anchor to add the scene to
    ///   - isNight: Whether to configure the night mode version of the scene
    private func configureFireflyScene(for anchor: AnchorEntity, isNight: Bool) {
        // Load the appropriate USDZ model based on day/night mode
        let modelName = isNight ? selectedScene.nighttimeUSDZ : selectedScene.daytimeUSDZ
        
        // In a real implementation, we would load the USDZ model here
        // For now, we'll create a simple environment with particle emitters
        
        // Create a simple environment
        let environment = createEnvironment(isNight: isNight)
        anchor.addChild(environment)
        
        // Create firefly particle emitters
        createFireflyParticles(for: anchor, isNight: isNight)
    }
    
    /// Create a simple environment entity
    /// - Parameter isNight: Whether to create a night environment
    /// - Returns: The environment entity
    private func createEnvironment(isNight: Bool) -> Entity {
        let environment = Entity()
        
        // Create a simple plane for the ground
        let planeMesh = MeshResource.generatePlane(width: 10, depth: 10)
        let planeMaterial = SimpleMaterial(color: isNight ? .black : .green, isMetallic: false)
        let plane = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        plane.position = [0, -1, 0]
        environment.addChild(plane)
        
        // Add ambient light
        let light = Entity()
        light.components[PointLightComponent.self] = PointLightComponent(
            color: isNight ? .blue : .white,
            intensity: isNight ? 500 : 1000,
            attenuationRadius: 5
        )
        light.position = [0, 2, 0]
        environment.addChild(light)
        
        return environment
    }
    
    /// Create firefly particle emitters
    /// - Parameters:
    ///   - anchor: The anchor to add the emitters to
    ///   - isNight: Whether to create night mode emitters
    private func createFireflyParticles(for anchor: AnchorEntity, isNight: Bool) {
        // Clear any existing emitters
        particleEmitters.removeAll()
        
        // Create multiple emitters at different positions
        let emitterCount = isNight ? 10 : 3
        
        for i in 0..<emitterCount {
            // Create a particle emitter for fireflies
            let emitter = createFireflyEmitter(isNight: isNight)
            
            // Position the emitter randomly within a sphere
            let radius: Float = isNight ? 3.0 : 2.0
            let angle = Float(i) * (2 * .pi / Float(emitterCount))
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            let y = Float.random(in: 0...1.5)
            
            emitter.position = [x, y, z]
            
            // Add the emitter to the anchor
            anchor.addChild(emitter)
            
            // Store the emitter for later updates
            particleEmitters.append(emitter)
        }
    }
    
    /// Create a firefly particle emitter
    /// - Parameter isNight: Whether to create a night mode emitter
    /// - Returns: The particle emitter entity
    private func createFireflyEmitter(isNight: Bool) -> ParticleEmitter {
        // Create a particle emitter for fireflies
        let emitter = ParticleEmitter()
        
        // Configure the emitter
        emitter.mainEmitter.birthRate = isNight ? 5.0 : 1.0
        emitter.mainEmitter.lifetime = 5.0
        emitter.mainEmitter.lifetimeSpread = 2.0
        emitter.mainEmitter.speed = 0.1
        emitter.mainEmitter.speedSpread = 0.05
        emitter.mainEmitter.particleSize = [0.02, 0.02, 0.02]
        emitter.mainEmitter.particleSizeSpread = [0.01, 0.01, 0.01]
        
        // Set initial color
        let startColor = isNight ? UIColor(hex: "#5D88F0") : UIColor(hex: "#FFFFFF")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        startColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        emitter.mainEmitter.tint = [Float(r), Float(g), Float(b)]
        emitter.mainEmitter.tintSpread = [0.1, 0.1, 0.1]
        
        // Configure emitter behavior
        emitter.mainEmitter.spreadingAngle = 180.0 // Emit in all directions
        emitter.mainEmitter.acceleration = [0, 0.01, 0] // Slight upward drift
        
        return emitter
    }
    
    /// Start playing the background music
    private func playMusic() {
        let result = MusicService.shared.playMusic(filename: selectedScene.backgroundMusicFileName)
        isPlaying = result
        duration = MusicService.shared.getDuration()
        MusicService.shared.setVolume(volume: volume)
    }
    
    /// Set up the dynamic drivers (display link for animation)
    private func setupDynamicDrivers() {
        // Remove any existing display link
        displayLink?.invalidate()
        
        // Create a new display link
        displayLink = CADisplayLink(target: self, selector: #selector(updateSceneDynamicProperties))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /// Update the scene's dynamic properties based on emotion script and music
    @objc private func updateSceneDynamicProperties() {
        // Get the current time
        currentTime = MusicService.shared.getCurrentTime()
        
        // Calculate delta time for smooth animations
        let currentTime = CACurrentMediaTime()
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        // Get the current emotion intensity and target color
        let intensity = EmotionScriptService.shared.getCurrentEmotionIntensity()
        let targetColor = EmotionScriptService.shared.getCurrentTargetColor()
        
        // Get the current music volume/power
        let musicPower = MusicService.shared.getAveragePower()
        
        // Apply the dynamic properties to the scene
        applyDynamicProperties(intensity: intensity, color: targetColor, musicVolume: musicPower)
    }
    
    /// Apply dynamic properties to the scene
    /// - Parameters:
    ///   - intensity: The emotion intensity (0.0 to 1.0)
    ///   - color: The target color
    ///   - musicVolume: The music volume/power (0.0 to 1.0)
    private func applyDynamicProperties(intensity: Double, color: UIColor, musicVolume: Float) {
        // Apply brightness factor to all dynamic properties
        // Extract color components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Update each particle emitter
        for emitter in particleEmitters {
            // Update color
            emitter.mainEmitter.tint = [Float(r), Float(g), Float(b)]
            
            // Update birth rate based on intensity and brightness
            let baseBirthRate: Float = isNightMode ? 5.0 : 1.0
            let intensityFactor = Float(intensity) * 2.0
            emitter.mainEmitter.birthRate = baseBirthRate * intensityFactor * Float(sceneBrightness * 1.2)
            
            // Update particle size based on music volume and brightness
            let baseSize: Float = 0.02
            let musicFactor = 1.0 + musicVolume * 0.5
            let brightnessFactor = Float(0.7 + sceneBrightness * 0.6)
            emitter.mainEmitter.particleSize = [baseSize * musicFactor * brightnessFactor, baseSize * musicFactor * brightnessFactor, baseSize * musicFactor * brightnessFactor]
        }
        
        // Update the scene anchor's light (if any)
        if let anchor = sceneAnchor {
            for child in anchor.children {
                if let lightEntity = child.children.first(where: { $0.components[PointLightComponent.self] != nil }) {
                    if var light = lightEntity.components[PointLightComponent.self] {
                        light.color = [Float(r), Float(g), Float(b)]
                        light.intensity = (500 + 500 * Float(intensity)) * Float(sceneBrightness * 1.5)
                        lightEntity.components[PointLightComponent.self] = light
                    }
                }
            }
        }
    }
}
