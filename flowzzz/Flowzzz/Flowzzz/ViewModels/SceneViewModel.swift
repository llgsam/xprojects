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
    
    // 新增场景亮度和萤火虫数量控制
    @Published var sceneBrightness: Float = 0.3 // 默认亮度值
    @Published var fireflyCount: Int = 60 // 默认萤火虫数量
    
    // 调试信息显示控制
    @Published var showDebugInfo: Bool = false
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var displayLink: CADisplayLink?
    // 将sceneAnchor从私有改为公开，以便于手势交互
    var sceneAnchor: AnchorEntity?
    // 添加主模型实体引用，用于手势交互
    var mainModelEntity: ModelEntity?
    private var particleEmitters: [ParticleEmitter] = []
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Initialization
    init() {
        // 默认设置为夜间模式，加载FireflyNighttime.usdz
        isNightMode = true
        
        // We'll set up services lazily when they're needed, not at init time
    }
    
    // MARK: - Public Methods
    
    /// Load the initial scene into the provided RealityKit view
    /// - Parameter view: The ARView to load the scene into
    func loadInitialScene(into view: ARView) {
        print("[DEBUG] 开始加载初始场景，夜间模式: \(isNightMode)")
        
        // 禁用AR会话自动启动
        view.automaticallyConfigureSession = false
        
        // 如果会话已经运行，停止它
        view.session.pause()
        
        // 根据showDebugInfo设置添加视图调试选项
        updateDebugOptions(for: view)
        
        // 加载场景 - 先加载视觉元素，后台加载服务
        loadScene(type: selectedScene, isNightMode: isNightMode, into: view)
        
        // 在主线程上延迟加载服务，不阻塞界面显示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupServices() // 延迟加载服务
            self?.setupDynamicDrivers() // 延迟设置动态驱动
            print("[DEBUG] 后台服务加载完成")
        }
        
        print("[DEBUG] 初始场景视觉元素加载完成")
    }
    
    /// 加载基本3D场景
    private func load3DScene(into view: ARView) {
        print("[DEBUG] 加载模拟器替代场景")
        
        // 创建一个基本场景
        let anchor = AnchorEntity()
        sceneAnchor = anchor
        
        // 添加一个简单的背景平面
        let planeMesh = MeshResource.generatePlane(width: 10, depth: 10)
        let planeMaterial = SimpleMaterial(color: isNightMode ? UIColor.black : UIColor.blue, isMetallic: false)
        let plane = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        plane.position = [0, -1, -2]
        anchor.addChild(plane)
        
        // 添加一个文本提示
        let textMesh = MeshResource.generateText(
            "模拟器模式\n请在真机上运行",
            extrusionDepth: 0.1,
            font: .systemFont(ofSize: 0.2),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let textMaterial = SimpleMaterial(color: UIColor.white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = [0, 0, -1.5]
        anchor.addChild(textEntity)
        
        // 添加一些简单的粒子效果
        for i in 0..<5 {
            let sphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.1),
                                    materials: [SimpleMaterial(color: UIColor.yellow, isMetallic: false)])
            let x = Float(i) * 0.5 - 1.0
            sphere.position = [x, 0.5, -1.5]
            
            // 添加光源
            var light = PointLightComponent(color: UIColor.yellow, intensity: 300)
            light.attenuationRadius = 1.0
            sphere.components[PointLightComponent.self] = light
            
            anchor.addChild(sphere)
            particleEmitters.append(ParticleEmitter()) // 仅为了保持一致性
        }
        
        // 添加到场景
        view.scene.anchors.append(anchor)
        
        // 播放音乐
        playMusic()
        setupDynamicDrivers()
        
        print("[DEBUG] 模拟器替代场景加载完成")
    }
    
    /// 配置3D视图
    private func configure3DView(for view: ARView) {
        print("[DEBUG] 配置3D视图")
        
        // 禁用AR会话
        view.automaticallyConfigureSession = false
        view.session.pause()
        
        // 设置环境
        view.environment.background = .color(isNightMode ? .black : .blue)
        
        print("[DEBUG] 3D视图配置完成")
    }
    
    /// 设置3D视图
    private func setup3DView(for view: ARView) {
        print("[DEBUG] 设置3D视图")
        
        // 配置3D视图
        configure3DView(for: view)
    }
    
    /// Select a new scene type
    /// - Parameter sceneType: The scene type to select
    func selectScene(_ sceneType: ImmersiveSceneType) {
        // Currently only firefly scene is supported
        if sceneType == .firefly {
            selectedScene = sceneType
        }
    }
    
    /// Unload the current scene from the provided RealityKit view
    /// - Parameter view: The ARView to unload the scene from
    func unloadCurrentScene(from view: ARView) {
        if let anchor = sceneAnchor {
            view.scene.anchors.remove(anchor)
            sceneAnchor = nil
        }
        
        particleEmitters.removeAll()
    }
    
    /// Load a scene into the provided RealityKit view
    /// - Parameters:
    ///   - type: The type of scene to load
    ///   - isNightMode: Whether to load the night mode version of the scene
    ///   - view: The ARView to load the scene into
    func loadScene(type: ImmersiveSceneType, isNightMode: Bool, into view: ARView) {
        print("[DEBUG] 开始加载场景: \(type.rawValue), 夜间模式: \(isNightMode)")
        
        // Unload any existing scene
        unloadCurrentScene(from: view)
        
        // Create a new anchor
        let anchor = AnchorEntity()
        sceneAnchor = anchor
        
        // Configure the scene based on the type
        switch type {
        case .firefly:
            configureFireflyScene(for: anchor, isNight: isNightMode)
        }
        
        // Add the anchor to the scene
        if let sceneAnchor = sceneAnchor {
            view.scene.anchors.append(sceneAnchor)
            print("[DEBUG] 场景锁点已添加到场景")
        } else {
            print("[ERROR] 场景锁点为nil，无法添加到场景")
        }
        
        // Start the music
        print("[DEBUG] 开始播放音乐")
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
        reloadScene()
    }
    
    /// Reload the scene with current settings
    func reloadScene() {
        // 清除当前场景
        clearScene()
        
        // 创建新的场景锚点
        sceneAnchor = AnchorEntity()
        
        // 重新加载场景
        if let anchor = sceneAnchor {
            // 加载模型
            configureFireflyScene(for: anchor, isNight: isNightMode)
            
            // 创建粒子
            createFireflyParticles(for: anchor, isNight: isNightMode)
            
            print("[DEBUG] 重新加载场景，亮度: \(sceneBrightness), 萤火虫数量: \(fireflyCount)")
        }
    }
    
    /// 切换调试信息显示状态
    /// - Parameter view: 可选的ARView参数，如果提供则立即更新视图
    func toggleDebugInfo(for view: ARView? = nil) {
        showDebugInfo.toggle()
        print("[DEBUG] 调试信息显示已切换为: \(showDebugInfo ? "开启" : "关闭")")
        
        // 如果提供了视图，立即更新调试选项
        if let view = view {
            updateDebugOptions(for: view)
        }
        
        // 通知其他组件调试状态已更改
        NotificationCenter.default.post(name: .debugInfoToggled, object: nil)
    }
    
    /// 根据当前设置更新ARView的调试选项
    /// - Parameter view: 要更新的ARView
    func updateDebugOptions(for view: ARView) {
        if showDebugInfo {
            view.debugOptions = [.showStatistics, .showFeaturePoints]
        } else {
            view.debugOptions = []
        }
    }
    
    /// Clear the current scene
    private func clearScene() {
        // 清除粒子发射器
        particleEmitters.removeAll()
        
        // 移除所有子实体
        sceneAnchor?.children.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Set up services and observers
    private func setupServices() {
        // Load the emotion script
        EmotionScriptService.shared.loadScript(named: "firefly_emotion_script")
    }
    
    /// Configure the firefly scene
    /// - Parameters:
    ///   - anchor: The anchor to add the scene to
    ///   - isNight: Whether to configure the night mode version of the scene
    private func configureFireflyScene(for anchor: AnchorEntity, isNight: Bool) {
        print("[DEBUG] 开始配置萤火虫场景, 夜间模式: \(isNight)")
        
        // 加载适合的USDZ模型
        let modelName = isNight ? selectedScene.nighttimeUSDZ : selectedScene.daytimeUSDZ
        print("[DEBUG] 加载模型: \(modelName)")
        
        // 加载并渲染USDZ模型
        do {
            // 尝试从资源中加载模型
            let modelEntity = try ModelEntity.loadModel(named: modelName)
            print("[DEBUG] 模型加载成功")
            
            // 调整模型位置和缩放
            modelEntity.position = [0, 0, -1] // 将模型放在前方
            
            // 模型文件本身方向已经正确，不需要额外旋转
            
            // 设置初始缩放
            let initialScale: Float = 0.5
            modelEntity.scale = [initialScale, initialScale, initialScale]
            
            // 存储模型引用以便于后续缩放 - 使用属性而不是components
            // 创建一个属性来存储主模型引用
            self.mainModelEntity = modelEntity
            
            // 添加到场景中
            anchor.addChild(modelEntity)
            print("[DEBUG] 模型已添加到场景，旋转角度已调整")
        } catch {
            print("[ERROR] 无法加载模型: \(error.localizedDescription)")
            print("[DEBUG] 回退到创建基本环境")
            
            // 如果模型加载失败，创建一个基本环境
            let environment = createEnvironment(isNight: isNight)
            anchor.addChild(environment)
        }
        
        // 创建萤火虫粒子发射器 - 增强粒子效果
        createFireflyParticles(for: anchor, isNight: isNight)
        print("[DEBUG] 萤火虫粒子发射器已创建")
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
        
        // 添加更强的环境光照
        let light = Entity()
        light.components[PointLightComponent.self] = PointLightComponent(
            color: isNight ? .blue : .white,
            intensity: isNight ? 2000 : 3000,
            attenuationRadius: 10
        )
        light.position = [0, 2, 0]
        environment.addChild(light)
        
        // 添加额外的光源以确保场景可见
        let secondaryLight = Entity()
        secondaryLight.components[PointLightComponent.self] = PointLightComponent(
            color: .white,
            intensity: 1000,
            attenuationRadius: 8
        )
        secondaryLight.position = [0, -1, 2]
        environment.addChild(secondaryLight)
        
        return environment
    }
    
    /// Create firefly particle emitters
    /// - Parameters:
    ///   - anchor: The anchor to add the emitters to
    ///   - isNight: Whether to create night mode emitters
    private func createFireflyParticles(for anchor: AnchorEntity, isNight: Bool) {
        print("[DEBUG] 开始创建萤火虫粒子，夜间模式: \(isNight)")
        
        // Clear any existing emitters
        particleEmitters.removeAll()
        
        // 使用用户设置的萤火虫数量
        let emitterCount = fireflyCount
        print("[DEBUG] 将创建 \(emitterCount) 个增强萤火虫发射器")
        
        for i in 0..<emitterCount {
            // Create a particle emitter for fireflies
            let emitter = createFireflyEmitter(isNight: isNight)
            
            // 将发射器放置在更靠近视图的位置，确保可见性
            let radius: Float = isNight ? 3.0 : 2.0 // 增大半径
            let angle = Float(i) * (2 * .pi / Float(emitterCount))
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            let y = Float.random(in: -1.0...2.0) // 增大高度范围
            
            emitter.position = [x, y, z]
            print("[DEBUG] 粒子发射器 \(i) 位置: [\(x), \(y), \(z)]")
            
            // Add the emitter to the anchor
            anchor.addChild(emitter)
            
            // Store the emitter for later updates
            particleEmitters.append(emitter)
        }
        
        // 添加多个特别明显的发射器在中央位置
        for j in 0..<3 { // 添加三个中央发射器
            let centerEmitter = createFireflyEmitter(isNight: isNight)
            centerEmitter.position = [Float.random(in: -0.5...0.5), Float(j) * 0.5, Float.random(in: -0.5...0.5)]
            print("[DEBUG] 添加增强中央粒子发射器 \(j)")
            anchor.addChild(centerEmitter)
            particleEmitters.append(centerEmitter)
        }
        
        print("[DEBUG] 总共创建了 \(particleEmitters.count) 个增强粒子发射器")
    }
    
    /// Create a firefly particle emitter
    /// - Parameter isNight: Whether to create a night mode emitter
    /// - Returns: The particle emitter entity
    private func createFireflyEmitter(isNight: Bool) -> ParticleEmitter {
        // Create a particle emitter for fireflies
        let emitter = ParticleEmitter()
        
        // 显著增强发射器配置
        emitter.mainEmitter.birthRate = isNight ? 10.0 : 5.0 // 显著增加生成率
        emitter.mainEmitter.lifetime = 8.0 // 增加生命周期
        
        // 显著增大粒子尺寸
        emitter.mainEmitter.particleSize = [0.1, 0.1, 0.1] // 显著增大粒子尺寸
        
        // Set initial color
        let startColor = isNight ? UIColor(hex: "#5D88F0") : UIColor(hex: "#FFFFFF")
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        startColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        emitter.mainEmitter.tint = [Float(r), Float(g), Float(b)]
        emitter.mainEmitter.tintSpread = [0.1, 0.1, 0.1]
        
        // Configure emitter behavior
        emitter.mainEmitter.spreadingAngle = 180.0 // Emit in all directions
        emitter.mainEmitter.acceleration = [0, 0.01, 0] // Slight upward drift
        
        // Apply the updates to the particle
        emitter.updateParticle()
        
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
        _ = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
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
        // Extract color components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Update each particle emitter
        for emitter in particleEmitters {
            // Update color
            emitter.mainEmitter.tint = [Float(r), Float(g), Float(b)]
            
            // Update birth rate based on intensity
            let baseBirthRate: Float = isNightMode ? 5.0 : 1.0
            let intensityFactor = Float(intensity) * 2.0
            emitter.mainEmitter.birthRate = baseBirthRate * intensityFactor
            
            // Update particle size based on music volume
            let baseSize: Float = 0.02
            let musicFactor = 1.0 + musicVolume * 0.5
            emitter.mainEmitter.particleSize = [baseSize * musicFactor, baseSize * musicFactor, baseSize * musicFactor]
            
            // Apply updates to the particle
            emitter.updateParticle()
        }
        
        // Update the scene anchor's light (if any)
        if let anchor = sceneAnchor {
            for child in anchor.children {
                if let lightEntity = child.children.first(where: { $0.components[PointLightComponent.self] != nil }) {
                    if var light = lightEntity.components[PointLightComponent.self] {
                        light.color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                        light.intensity = 500 + 500 * Float(intensity)
                        lightEntity.components[PointLightComponent.self] = light
                    }
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let reloadSceneRequested = Notification.Name("reloadSceneRequested")
    static let debugInfoToggled = Notification.Name("debugInfoToggled")
}
