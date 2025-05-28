import SwiftUI

struct ContentView: View {
    @StateObject private var sceneViewModel = SceneViewModel()
    @StateObject private var musicService = MusicService.shared
    @StateObject private var watchService = WatchConnectivityService.shared
    
    var body: some View {
        ZStack {
            // Background - Immersive Scene
            ImmersiveSceneView(viewModel: sceneViewModel)
            
            // Control UI Overlay
            VStack {
                // Top Section - Title and Scene Info
                VStack(spacing: 8) {
                    Text("沉浸式睡前能量场")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(sceneViewModel.selectedScene.displayName)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Bottom Control Panel
                VStack(spacing: 20) {
                    // Music Controls
                    HStack(spacing: 30) {
                        // Play/Pause Button
                        Button(action: {
                            sceneViewModel.togglePlayPause()
                        }) {
                            Image(systemName: musicService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        // Volume Control
                        VStack {
                            Text("音量")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Slider(value: Binding(
                                get: { musicService.volume },
                                set: { sceneViewModel.setVolume($0) }
                            ), in: 0...1)
                            .accentColor(.white)
                            .frame(width: 120)
                        }
                    }
                    
                    // Progress Bar
                    if musicService.duration > 0 {
                        VStack(spacing: 4) {
                            ProgressView(value: musicService.currentTime, total: musicService.duration)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .frame(height: 4)
                            
                            HStack {
                                Text(formatTime(musicService.currentTime))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Spacer()
                                
                                Text(formatTime(musicService.duration))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Scene Controls
                    HStack(spacing: 20) {
                        // Night Mode Toggle
                        Button(action: {
                            sceneViewModel.toggleNightMode()
                        }) {
                            HStack {
                                Image(systemName: sceneViewModel.isNightMode ? "moon.fill" : "sun.max.fill")
                                Text(sceneViewModel.isNightMode ? "夜晚" : "白天")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }
                        
                        // Future Scene Selection (Placeholder)
                        Button(action: {
                            // TODO: Implement scene selection
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("场景")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .disabled(true) // Disabled for now
                        
                        // Watch Connection Status
                        if watchService.isWatchConnected {
                            HStack {
                                Image(systemName: "applewatch")
                                Text("已连接")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(15)
                        }
                    }
                    
                    // Emotion Intensity Indicator
                    VStack(spacing: 8) {
                        Text("情绪强度")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(sceneViewModel.currentTargetColor).opacity(0.3),
                                        Color(sceneViewModel.currentTargetColor)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: CGFloat(sceneViewModel.currentEmotionIntensity) * 200, height: 4)
                                .animation(.easeInOut(duration: 0.5), value: sceneViewModel.currentEmotionIntensity)
                            
                            Spacer()
                        }
                        .frame(width: 200, height: 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(2)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
} 