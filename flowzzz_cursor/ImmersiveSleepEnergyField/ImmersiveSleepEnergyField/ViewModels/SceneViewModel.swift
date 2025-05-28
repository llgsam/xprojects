import Foundation
import SwiftUI
import RealityKit
import ARKit

class SceneViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedScene: ImmersiveSceneType = .firefly
    @Published var isNightMode: Bool = true
    @Published var isSceneLoaded: Bool = false
    @Published var currentEmotionIntensity: Float = 0.5
    @Published var currentTargetColor: UIColor = .yellow
    
    // MARK: - Services
    private let musicService = MusicService.shared
    private let emotionService = EmotionScriptService.shared
    private let watchService = WatchConnectivityService.shared
    
    // MARK: - Scene Management
    private var currentSceneEntity: Entity?
    private var fireflyParticleEmitter: Entity?
    private var displayLink: CADisplayLink?
    
    // MARK: - Initialization
    init() {
        setupInitialState()
        setupDynamicDrivers()
    }
    
    deinit {
        stopDynamicDrivers()
    }
    
    // MARK: - Initial Setup
    private func setupInitialState() {
        // Determine initial night mode based on current time
        let hour = Calendar.current.component(.hour, from: Date())
        isNightMode = hour >= 18 || hour < 6
        
        // Load emotion script for firefly scene
        _ = emotionService.loadScript(named: selectedScene.emotionScriptFileName)
    }
    
    // MARK: - Scene Loading and Management
    func loadInitialScene(into arView: ARView) {
        loadScene(type: selectedScene, isNightMode: isNightMode, into: arView)
    }
    
    func selectScene(_ sceneType: ImmersiveSceneType) {
        guard sceneType != selectedScene else { return }
        selectedScene = sceneType
        
        // Load new emotion script
        _ = emotionService.loadScript(named: sceneType.emotionScriptFileName)
        
        // TODO: Reload scene in ARView when scene switching is implemented
        print("Scene selected: \(sceneType.displayName)")
    }
    
    func unloadCurrentScene(from arView: ARView) {
        currentSceneEntity?.removeFromParent()
        currentSceneEntity = nil
        fireflyParticleEmitter = nil
        isSceneLoaded = false
    }
    
    func loadScene(type: ImmersiveSceneType, isNightMode: Bool, into arView: ARView) {
        // Unload current scene first
        unloadCurrentScene(from: arView)
        
        switch type {
        case .firefly:
            configureFireflyScene(for: arView, isNight: isNightMode)
        }
        
        // Start music
        musicService.playMusic(filename: type.backgroundMusicFileName)
        
        // Start emotion script
        emotionService.startScript()
        
        isSceneLoaded = true
        
        // Update watch
        watchService.sendSceneUpdate(type, isNightMode: isNightMode)
    }
    
    // MARK: - Firefly Scene Configuration
    private func configureFireflyScene(for arView: ARView, isNight: Bool) {
        // Create main scene entity
        let sceneEntity = Entity()
        
        // Load USDZ model based on day/night mode
        let usdzFileName = isNight ? selectedScene.nighttimeUSDZ : selectedScene.daytimeUSDZ
        
        // Try to load USDZ file
        if let usdzURL = Bundle.main.url(forResource: usdzFileName, withExtension: "usdz") {
            do {
                let modelEntity = try Entity.load(contentsOf: usdzURL)
                sceneEntity.addChild(modelEntity)
                print("Loaded USDZ model: \(usdzFileName)")
            } catch {
                print("Failed to load USDZ model \(usdzFileName): \(error)")
                // Continue with particle-only scene
            }
        } else {
            print("USDZ file not found: \(usdzFileName).usdz - using particle-only scene")
        }
        
        // Create firefly particle system
        createFireflyParticleSystem(parent: sceneEntity, isNight: isNight)
        
        // Add scene to ARView
        let anchor = AnchorEntity(world: [0, 0, -2])
        anchor.addChild(sceneEntity)
        arView.scene.addAnchor(anchor)
        
        currentSceneEntity = sceneEntity
        
        // Configure lighting
        configureSceneLighting(arView: arView, isNight: isNight)
    }
    
    private func createFireflyParticleSystem(parent: Entity, isNight: Bool) {
        // Create particle emitter entity
        let particleEntity = Entity()
        
        // Configure particle emitter component
        var particleEmitter = ParticleEmitterComponent()
        
        // Basic particle configuration
        particleEmitter.emissionShape = .sphere
        particleEmitter.birthRate = isNight ? 50.0 : 10.0
        particleEmitter.lifeSpan = 3.0
        particleEmitter.lifespanVariation = 1.0
        
        // Particle appearance
        particleEmitter.speed = 0.1
        particleEmitter.speedVariation = 0.05
        particleEmitter.scale = 0.02
        particleEmitter.scaleVariation = 0.01
        
        // Color configuration (will be updated dynamically)
        particleEmitter.color = .evolving(
            start: .single(.yellow),
            end: .single(.orange)
        )
        
        // Emission area
        particleEmitter.emissionShapeSize = [2.0, 1.0, 2.0]
        
        // Add particle emitter to entity
        particleEntity.components.set(particleEmitter)
        
        // Position the particle emitter
        particleEntity.position = [0, 0.5, 0]
        
        parent.addChild(particleEntity)
        fireflyParticleEmitter = particleEntity
        
        print("Created firefly particle system (night mode: \(isNight))")
    }
    
    private func configureSceneLighting(arView: ARView, isNight: Bool) {
        // Configure ambient lighting
        let intensity: Float = isNight ? 0.2 : 0.8
        
        // Create directional light
        let lightEntity = Entity()
        var directionalLight = DirectionalLightComponent()
        directionalLight.intensity = intensity * 1000 // Lux
        directionalLight.color = isNight ? .blue : .white
        lightEntity.components.set(directionalLight)
        
        // Position light
        lightEntity.look(at: [0, -1, -1], from: [0, 1, 1], relativeTo: nil)
        
        // Add to scene
        if let anchor = arView.scene.anchors.first {
            anchor.addChild(lightEntity)
        }
    }
    
    // MARK: - Dynamic Updates
    private func setupDynamicDrivers() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateSceneDynamicProperties))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopDynamicDrivers() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateSceneDynamicProperties() {
        // Get current emotion values
        let intensity = emotionService.getCurrentEmotionIntensity()
        let targetColor = emotionService.getCurrentTargetColor()
        
        // Get music power (for future audio-reactive features)
        let musicPower = musicService.getAveragePower()
        
        // Update published properties
        currentEmotionIntensity = intensity
        currentTargetColor = targetColor
        
        // Apply dynamic properties to scene
        applyDynamicProperties(intensity: intensity, color: targetColor, musicPower: musicPower)
        
        // Update emotion service's published values
        emotionService.updateCurrentValues()
    }
    
    private func applyDynamicProperties(intensity: Float, color: UIColor, musicPower: Float) {
        guard let particleEmitter = fireflyParticleEmitter else { return }
        
        // Update particle emitter properties
        if var emitterComponent = particleEmitter.components[ParticleEmitterComponent.self] {
            // Update birth rate based on emotion intensity
            let baseBirthRate: Float = isNightMode ? 50.0 : 10.0
            emitterComponent.birthRate = baseBirthRate * (0.5 + intensity)
            
            // Update particle color based on target color
            let particleColor = convertUIColorToRealityKitColor(color)
            emitterComponent.color = .evolving(
                start: .single(particleColor),
                end: .single(particleColor.withAlphaComponent(0.3))
            )
            
            // Update scale based on music power (subtle effect)
            let baseScale: Float = 0.02
            let scaleMultiplier = 1.0 + (musicPower * 0.3)
            emitterComponent.scale = baseScale * scaleMultiplier
            
            // Apply updated component
            particleEmitter.components.set(emitterComponent)
        }
    }
    
    private func convertUIColorToRealityKitColor(_ uiColor: UIColor) -> RealityKit.Material.Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return RealityKit.Material.Color(
            red: Float(red),
            green: Float(green),
            blue: Float(blue),
            alpha: Float(alpha)
        )
    }
    
    // MARK: - User Actions
    func toggleNightMode() {
        isNightMode.toggle()
        
        // TODO: Reload scene with new mode
        print("Night mode toggled: \(isNightMode)")
        
        // Update watch
        watchService.sendSceneUpdate(selectedScene, isNightMode: isNightMode)
    }
    
    func togglePlayPause() {
        if musicService.isPlaying {
            musicService.pause()
            emotionService.stopScript()
        } else {
            musicService.resume()
            emotionService.startScript()
        }
        
        // Update watch
        watchService.updateApplicationContext()
    }
    
    func setVolume(_ volume: Float) {
        musicService.setVolume(volume)
        watchService.sendVolumeUpdate(volume)
    }
} 