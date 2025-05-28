import SwiftUI

/// Main content view for the application
struct ContentView: View {
    @StateObject private var viewModel = SceneViewModel()
    
    var body: some View {
        ZStack {
            // Background - full screen immersive scene
            ImmersiveSceneView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay controls
            VStack {
                // Title
                Text(viewModel.selectedScene.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                    .padding(.top, 40)
                
                Spacer()
                
                // Control panel at the bottom
                VStack(spacing: 20) {
                    // Progress bar
                    ProgressView(value: viewModel.currentTime, total: viewModel.duration)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.white))
                        .padding(.horizontal)
                    
                    // Time display
                    HStack {
                        Text(formatTime(viewModel.currentTime))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(formatTime(viewModel.duration))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Playback controls
                    HStack(spacing: 30) {
                        // Volume control
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.white)
                            
                            Slider(value: $viewModel.volume, in: 0...1) { _ in
                                viewModel.setVolume(viewModel.volume)
                            }
                            .frame(width: 100)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.white)
                        }
                        
                        // Play/Pause button
                        Button(action: {
                            viewModel.togglePlayback()
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                        }
                        
                        // Day/Night mode toggle
                        Button(action: {
                            viewModel.toggleNightMode()
                        }) {
                            Image(systemName: viewModel.isNightMode ? "moon.fill" : "sun.max.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    // 场景亮度控制
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "sun.min")
                                .foregroundColor(.white)
                            
                            Slider(value: $viewModel.sceneBrightness, in: 0...1) { isEditing in
                                // 只在拖动结束时重新加载场景
                                if !isEditing {
                                    viewModel.reloadScene()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            // 禁用触觉反馈以避免CoreHaptics错误
                            //.sensoryFeedback(.impact(weight: .light), trigger: .never)
                            
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        
                        Text("Scene Brightness: \(Int(viewModel.sceneBrightness * 100))%")
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // 萤火虫数量控制
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "sparkles.tv")
                                .foregroundColor(.white)
                            
                            Slider(value: Binding<Double>(
                                get: { Double(viewModel.fireflyCount) },
                                set: { viewModel.fireflyCount = Int($0) }
                            ), in: 10...200) { isEditing in
                                // 只在拖动结束时重新加载场景
                                if !isEditing {
                                    viewModel.reloadScene()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            // 禁用触觉反馈以避免CoreHaptics错误
                            //.sensoryFeedback(.impact(weight: .light), trigger: .never)
                            
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        
                        Text("Firefly Count: \(viewModel.fireflyCount)")
                            .foregroundColor(.white)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Scene selection (placeholder for future scenes)
                    HStack {
                        Text("Scene:")
                            .foregroundColor(.white)
                        
                        Picker("Scene", selection: $viewModel.selectedScene) {
                            ForEach(ImmersiveSceneType.allCases) { scene in
                                Text(scene.displayName)
                                    .foregroundColor(.white)
                                    .tag(scene)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(true) // Disabled since only firefly scene is available
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 30)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(15)
                .padding()
            }
        }
    }
    
    /// Format time in mm:ss format
    /// - Parameter timeInSeconds: Time in seconds
    /// - Returns: Formatted time string
    private func formatTime(_ timeInSeconds: TimeInterval) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
