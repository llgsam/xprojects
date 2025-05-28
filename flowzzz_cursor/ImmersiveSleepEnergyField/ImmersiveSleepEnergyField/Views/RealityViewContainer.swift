import SwiftUI
import RealityKit
import ARKit

struct RealityViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: SceneViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration)
        
        // Load initial scene
        viewModel.loadInitialScene(into: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Handle updates if needed
        // For now, dynamic updates are handled through the ViewModel's CADisplayLink
    }
} 