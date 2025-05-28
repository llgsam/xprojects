import Foundation
import RealityKit
import UIKit

/// A custom particle emitter class that simulates firefly particles
class ParticleEmitter: Entity {
    // MARK: - Properties
    
    /// The main particle emitter component structure
    class EmitterComponent {
        // 增加发射率和寿命
        var birthRate: Float = 10.0 // 增加发射率
        var lifetime: Float = 5.0 // 增加寿命
        var lifetimeSpread: Float = 3.0 // 增加寿命变化范围
        
        // 增加速度和变化
        var speed: Float = 0.3 // 增加速度
        var speedSpread: Float = 0.2 // 增加速度变化
        
        // 显著增大粒子尺寸
        var particleSize: [Float] = [0.3, 0.3, 0.3] // 显著增大粒子尺寸
        var particleSizeSpread: [Float] = [0.1, 0.1, 0.1] // 增加尺寸变化
        
        // 更鲜艳的颜色
        var tint: [Float] = [1.0, 0.9, 0.1] // 更鲜艳的黄色
        var tintSpread: [Float] = [0.2, 0.3, 0.0] // 增加颜色变化
        
        // 更随机的运动
        var velocity: [Float] = [0.0, 0.1, 0.0] // 基础向上运动
        var velocitySpread: [Float] = [0.3, 0.3, 0.3] // 增加随机性
        var acceleration: [Float] = [0.0, 0.02, 0.0] // 轻微向上加速
        var spreadingAngle: Float = 360.0 // 全方位扩散
    }
    
    /// The main particle emitter component
    var mainEmitter = EmitterComponent()
    
    /// The model entity that represents the particle
    private var particleEntity: ModelEntity?
    
    /// 用于存储飞行动画的计时器
    private var flightTimer: Timer?
    
    // MARK: - Initialization
    
    /// Initialize a new particle emitter with default settings
    required init() {
        super.init()
        print("[DEBUG] 创建新的增强萤火虫发射器实例")
        particleEntity = setupParticleEntity()
        addParticleEntity()
    }
    
    /// Setup the particle entity with enhanced visuals
    private func setupParticleEntity() -> ModelEntity? {
        // 创建一个球体网格作为萤火虫光源 - 更大的半径
        let sphereMesh = MeshResource.generateSphere(radius: 0.3) // 大尺寸萤火虫
        
        // 创建发光材质 - 使用更鲜艳的黄绿色
        let baseColor: UIColor
        if Bool.random() { // 随机选择颜色变化
            // 黄色偏向的萤火虫
            baseColor = UIColor(red: 1.0, green: CGFloat.random(in: 0.8...1.0), blue: CGFloat.random(in: 0.0...0.2), alpha: 1.0)
        } else {
            // 绿色偏向的萤火虫
            baseColor = UIColor(red: CGFloat.random(in: 0.7...0.9), green: 1.0, blue: CGFloat.random(in: 0.0...0.2), alpha: 1.0)
        }
        
        let material = SimpleMaterial(
            color: baseColor,
            roughness: 0.0, // 完全光滑
            isMetallic: true // 金属效果增强亮度
        )
        
        let entity = ModelEntity(mesh: sphereMesh, materials: [material])
        
        // 设置随机初始位置
        let randomPosition = SIMD3<Float>(
            Float.random(in: -2...2),
            Float.random(in: -1...2),
            Float.random(in: -2...2)
        )
        entity.position = randomPosition
        
        print("[DEBUG] 创建增强萤火虫粒子实体，半径: 0.3，颜色随机变化，位置随机")
        return entity
    }
    
    // MARK: - Particle Entity Setup
    
    /// Add the particle entity as a child and setup effects
    private func addParticleEntity() {
        guard let entity = particleEntity else {
            print("[ERROR] 粒子实体创建失败")
            return
        }
        
        addChild(entity)
        print("[DEBUG] 将萤火虫粒子实体添加为子实体")
        
        // 设置增强的点光源 - 使用随机颜色
        let lightColor: UIColor
        if Bool.random() {
            // 黄色系
            lightColor = UIColor(red: 1.0, green: CGFloat.random(in: 0.8...1.0), blue: 0.0, alpha: 1.0)
        } else {
            // 绿色系
            lightColor = UIColor(red: CGFloat.random(in: 0.5...0.8), green: 1.0, blue: 0.0, alpha: 1.0)
        }
        
        var pointLight = PointLightComponent(
            color: lightColor,
            intensity: Float.random(in: 800...1200),  // 随机强度
            attenuationRadius: Float.random(in: 1.5...3.0)  // 随机衰减半径
        )
        entity.components[PointLightComponent.self] = pointLight
        print("[DEBUG] 添加增强萤火虫光源，随机颜色、强度和衰减半径")
        
        // 添加自然的闪烁效果 - 使用随机间隔和强度变化
        addNaturalFlickerEffect(to: entity)
        
        // 添加随机飞行动画
        addRandomFlightAnimation(to: entity)
    }
    
    /// Add natural flickering effect to the entity
    private func addNaturalFlickerEffect(to entity: ModelEntity) {
        DispatchQueue.global().async {
            // 使用随机初始值和变化率
            var currentIntensity = Float.random(in: 700...1300)
            let baseIntensity = currentIntensity
            
            // 随机决定初始方向
            var isIncreasing = Bool.random()
            
            while true {
                // 随机变化率 - 使闪烁更自然
                let changeRate = Float.random(in: 30...150)
                
                // 模拟自然闪烁效果
                if isIncreasing {
                    currentIntensity += changeRate
                    // 随机上限
                    let upperLimit = baseIntensity + Float.random(in: 300...700)
                    if currentIntensity >= upperLimit {
                        isIncreasing = false
                    }
                } else {
                    currentIntensity -= changeRate
                    // 随机下限
                    let lowerLimit = max(baseIntensity - Float.random(in: 300...500), 300)
                    if currentIntensity <= lowerLimit {
                        isIncreasing = true
                    }
                }
                
                // 在主线程上更新光源
                DispatchQueue.main.async {
                    if var light = entity.components[PointLightComponent.self] {
                        light.intensity = currentIntensity
                        entity.components[PointLightComponent.self] = light
                    }
                }
                
                // 随机间隔 - 使闪烁更自然
                let sleepInterval = Double.random(in: 0.03...0.12)
                Thread.sleep(forTimeInterval: sleepInterval)
            }
        }
        
        print("[DEBUG] 添加自然闪烁效果，随机强度和间隔")
    }
    
    /// Add random flight animation to simulate firefly movement
    private func addRandomFlightAnimation(to entity: ModelEntity) {
        // 创建一个定时器来周期性地改变位置
        DispatchQueue.global().async {
            while true {
                // 生成随机目标位置
                let targetPosition = SIMD3<Float>(
                    Float.random(in: -2...2),
                    Float.random(in: -1...2),
                    Float.random(in: -2...2)
                )
                
                // 计算当前位置到目标位置的向量
                let currentPosition = entity.position
                let moveVector = targetPosition - currentPosition
                
                // 动画持续时间 - 随机
                let animationDuration = Float.random(in: 2.0...5.0)
                
                // 动画步数
                let steps = Int(animationDuration * 20) // 每秒20步
                
                // 每步移动距离
                let stepVector = moveVector / Float(steps)
                
                // 执行平滑移动
                for step in 0..<steps {
                    // 在主线程上更新位置
                    DispatchQueue.main.async {
                        // 添加一些随机抖动，模拟萤火虫飞行的不规则性
                        let jitter = SIMD3<Float>(
                            Float.random(in: -0.02...0.02),
                            Float.random(in: -0.02...0.02),
                            Float.random(in: -0.02...0.02)
                        )
                        
                        entity.position += stepVector + jitter
                    }
                    
                    // 每步之间的延迟
                    Thread.sleep(forTimeInterval: Double(animationDuration) / Double(steps))
                }
                
                // 在目标位置停留一段随机时间
                let pauseDuration = Double.random(in: 0.5...2.0)
                Thread.sleep(forTimeInterval: pauseDuration)
            }
        }
        
        print("[DEBUG] 添加随机飞行动画，模拟萤火虫自然飞行")
    }
    
    /// Update the particle appearance based on emitter properties
    func updateParticle() {
        guard let entity = particleEntity else { 
            print("[ERROR] 无法更新粒子：粒子实体为nil")
            return 
        }
        
        // 生成随机颜色 - 比简单转换更生动
        let randomFactor = Float.random(in: 0.8...1.2)
        let color = UIColor(
            red: CGFloat(min(mainEmitter.tint[0] * randomFactor, 1.0)), 
            green: CGFloat(min(mainEmitter.tint[1] * randomFactor, 1.0)), 
            blue: CGFloat(min(mainEmitter.tint[2] * 0.5, 0.3)), // 限制蓝色成分
            alpha: 1.0
        )
        
        // 更新材质
        if var modelComponent = entity.components[ModelComponent.self] {
            let newMaterial = SimpleMaterial(
                color: color,
                roughness: 0.0,
                isMetallic: true
            )
            modelComponent.materials = [newMaterial]
            entity.components[ModelComponent.self] = modelComponent
        }
        
        // 更新光源
        if var light = entity.components[PointLightComponent.self] {
            light.color = color
            // 随机调整光强度
            light.intensity = Float.random(in: 800...1500)
            // 随机调整衰减半径
            light.attenuationRadius = Float.random(in: 1.5...3.0)
            entity.components[PointLightComponent.self] = light
        }
        
        // 随机更新尺寸
        let sizeVariation = Float.random(in: 0.8...1.2)
        let baseSize = mainEmitter.particleSize[0] * sizeVariation
        entity.scale = [baseSize, baseSize, baseSize]
    }
}
