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
        arView.session.run(configuration)
        
        // Set debug options based on user preference
        updateDebugOptions(for: arView)
        
        // Load the initial scene
        viewModel.loadInitialScene(into: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Handle updates to the view model
        if context.coordinator.lastNightMode != viewModel.isNightMode {
            // Reload the scene when night mode changes
            viewModel.loadScene(type: viewModel.selectedScene, isNightMode: viewModel.isNightMode, into: uiView)
            context.coordinator.lastNightMode = viewModel.isNightMode
        }
        
        // Update debug options if debug mode changed
        if context.coordinator.lastDebugMode != viewModel.showDebugInfo {
            updateDebugOptions(for: uiView)
            context.coordinator.lastDebugMode = viewModel.showDebugInfo
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Update debug options based on the current debug mode setting
    private func updateDebugOptions(for arView: ARView) {
        if viewModel.showDebugInfo {
            // Show debug statistics when debug mode is enabled
            arView.debugOptions = [.showStatistics, .showFeaturePoints]
        } else {
            // Hide debug information when debug mode is disabled
            arView.debugOptions = []
        }
    }
    
    class Coordinator: NSObject {
        var parent: RealityViewContainer
        var lastNightMode: Bool
        var lastDebugMode: Bool
        
        init(_ parent: RealityViewContainer) {
            self.parent = parent
            self.lastNightMode = parent.viewModel.isNightMode
            self.lastDebugMode = parent.viewModel.showDebugInfo
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
