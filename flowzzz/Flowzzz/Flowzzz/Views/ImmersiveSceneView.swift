import SwiftUI
import RealityKit
import ARKit
import Combine

/// SwiftUI view that displays the immersive scene
struct ImmersiveSceneView: View {
    @ObservedObject var viewModel: SceneViewModel
    
    var body: some View {
        ZStack {
            // RealityKit view container
            RealityViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI elements can be added here if needed
        }
    }
}

/// UIViewRepresentable wrapper for ARView to use in SwiftUI
struct RealityViewContainer: UIViewRepresentable {
    var viewModel: SceneViewModel
    
    func makeUIView(context: Context) -> ARView {
        // Create AR configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Create AR view
        let arView = ARView(frame: .zero)
        
        // 禁用AR会话自动启动，不需要相机
        arView.automaticallyConfigureSession = false
        arView.session.pause()
        
        // 设置背景颜色并应用亮度调节
        let backgroundColor: UIColor
        if viewModel.isNightMode {
            // 夜间模式 - 深蓝色背景，亮度可调
            let brightness = CGFloat(viewModel.sceneBrightness)
            backgroundColor = UIColor(red: 0.0, green: 0.0, blue: brightness, alpha: 1.0)
        } else {
            // 白天模式 - 浅蓝色背景，亮度可调
            let brightness = CGFloat(0.3 + viewModel.sceneBrightness * 0.7) // 范围从0.3到1.0
            backgroundColor = UIColor(red: brightness * 0.5, green: brightness * 0.7, blue: brightness, alpha: 1.0)
        }
        arView.environment.background = .color(backgroundColor)
        
        // 添加场景光照
        let intensity = viewModel.sceneBrightness * 300 // 根据亮度设置调整环境光照
        arView.environment.lighting.intensityExponent = intensity
        
        // Set debug options in development builds
        #if DEBUG
        arView.debugOptions = [.showStatistics]
        #endif
        
        // 添加缩放手势识别器
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // 添加旋转手势识别器
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        // 添加平移手势识别器
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 2
        arView.addGestureRecognizer(panGesture)
        
        // Load the initial scene
        viewModel.loadInitialScene(into: arView)
        
        // 存储ARView引用以便于协调器访问
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Handle updates to the view model
        if context.coordinator.lastNightMode != viewModel.isNightMode {
            // Reload the scene when night mode changes
            viewModel.loadScene(type: viewModel.selectedScene, isNightMode: viewModel.isNightMode, into: uiView)
            context.coordinator.lastNightMode = viewModel.isNightMode
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: RealityViewContainer
        var lastNightMode: Bool
        weak var arView: ARView?
        private var initialScale: Float = 1.0
        private var currentScale: Float = 1.0
        
        init(_ parent: RealityViewContainer) {
            self.parent = parent
            self.lastNightMode = parent.viewModel.isNightMode
        }
        
        // 处理缩放手势
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = arView, let modelEntity = parent.viewModel.mainModelEntity else { return }
            
            switch gesture.state {
            case .began:
                initialScale = currentScale
            case .changed:
                // 计算新的缩放值，限制在合理范围内
                let scale = Float(gesture.scale) * initialScale
                currentScale = min(max(scale, 0.1), 3.0) // 限制缩放范围在0.1到3.0之间
                
                // 直接应用缩放到主模型
                modelEntity.scale = [currentScale, currentScale, currentScale]
                
                print("[DEBUG] 模型缩放: \(currentScale)")
            default:
                break
            }
        }
        
        // 处理旋转手势
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView = arView, let modelEntity = parent.viewModel.mainModelEntity else { return }
            
            switch gesture.state {
            case .changed:
                // 创建旋转四元数
                let rotation = simd_quatf(angle: Float(gesture.rotation) * 0.1, axis: [0, 1, 0])
                
                // 应用旋转到主模型
                modelEntity.transform.rotation = modelEntity.transform.rotation * rotation
                
                // 重置手势旋转以避免累积
                gesture.rotation = 0
            default:
                break
            }
        }
        
        // 处理平移手势
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView, let modelEntity = parent.viewModel.mainModelEntity else { return }
            
            switch gesture.state {
            case .changed:
                let translation = gesture.translation(in: arView)
                
                // 将屏幕坐标转换为3D空间移动
                let moveX = Float(translation.x) * 0.01
                let moveY = Float(-translation.y) * 0.01 // 反转Y轴方向
                
                // 应用平移到主模型
                modelEntity.position += [moveX, moveY, 0]
                
                // 重置手势平移以避免累积
                gesture.setTranslation(.zero, in: arView)
            default:
                break
            }
        }
    }
}

#if DEBUG
struct ImmersiveSceneView_Previews: PreviewProvider {
    static var previews: some View {
        ImmersiveSceneView(viewModel: SceneViewModel())
    }
}
#endif
