import SwiftUI
import RealityKit

struct ImmersiveSceneView: View {
    @ObservedObject var viewModel: SceneViewModel
    
    var body: some View {
        ZStack {
            // RealityKit Scene
            RealityViewContainer(viewModel: viewModel)
                .ignoresSafeArea(.all)
            
            // Overlay UI (if needed)
            VStack {
                Spacer()
                
                // Scene status indicator
                if viewModel.isSceneLoaded {
                    HStack {
                        Circle()
                            .fill(Color(viewModel.currentTargetColor))
                            .frame(width: 12, height: 12)
                        
                        Text(viewModel.selectedScene.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text(viewModel.isNightMode ? "夜晚模式" : "白天模式")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

#Preview {
    ImmersiveSceneView(viewModel: SceneViewModel())
} 