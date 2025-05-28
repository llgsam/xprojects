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
                    HStack(spacing: 20) {
                        // Volume control
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.white)
                            
                            // Use onEditingChanged to control when volume changes are applied
                            // This reduces the frequency of haptic feedback attempts
                            Slider(value: $viewModel.volume, in: 0...1, onEditingChanged: { editing in
                                if !editing {
                                    viewModel.setVolume(viewModel.volume)
                                }
                            })
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
                        
                        // Debug mode toggle
                        Button(action: {
                            viewModel.showDebugInfo.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(viewModel.showDebugInfo ? .green : .white)
                        }
                    }
                    .padding()
                    
                    // Brightness control
                    HStack {
                        Image(systemName: "sun.min")
                            .foregroundColor(.white)
                        
                        // Improved slider implementation with debouncing to prevent UI freezing
                        Slider(value: Binding(
                            get: { viewModel.sceneBrightness },
                            set: { newValue in
                                // Update the value immediately for UI responsiveness
                                viewModel.sceneBrightness = newValue
                            }
                        ), in: 0...1, onEditingChanged: { editing in
                            // Store editing state
                            viewModel.isEditingBrightness = editing
                            
                            if !editing {
                                // When editing ends, ensure we apply the final value
                                viewModel.updateSceneBrightness()
                            }
                        })
                        .onChange(of: viewModel.sceneBrightness) { _ in
                            // Check if we should update based on our throttling logic
                            if viewModel.shouldUpdateBrightness() {
                                viewModel.updateSceneBrightness()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Image(systemName: "sun.max")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
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
