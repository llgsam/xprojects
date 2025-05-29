import SwiftUI
import CoreHaptics

/// Haptic feedback manager that safely handles device compatibility
class HapticManager {
    static let shared = HapticManager()
    
    // 使用UIKit触觉反馈，避免与RealityKit冲突
    private var lightImpactGenerator: UIImpactFeedbackGenerator?
    private var mediumImpactGenerator: UIImpactFeedbackGenerator?
    private var heavyImpactGenerator: UIImpactFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    
    // 标记是否完全禁用触觉反馈
    private var hapticsEnabled: Bool = true
    
    init() {
        // 检查用户偏好设置
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            // 默认关闭触觉反馈，避免与RealityKit冲突
            UserDefaults.standard.set(false, forKey: "hapticsEnabled")
        }
        
        hapticsEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")
        print("[DEBUG] 触觉反馈状态: \(hapticsEnabled ? "已启用" : "已禁用")")
        
        // 预先初始化UIKit触觉生成器
        prepareGenerators()
    }
    
    /// 预先初始化所有UIKit触觉生成器
    private func prepareGenerators() {
        print("[DEBUG] 初始化UIKit触觉生成器...")
        
        // 创建并准备各种强度的触觉生成器
        lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
        mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
        heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        selectionGenerator = UISelectionFeedbackGenerator()
        notificationGenerator = UINotificationFeedbackGenerator()
        
        // 预热生成器以减少第一次使用时的延迟
        lightImpactGenerator?.prepare()
        mediumImpactGenerator?.prepare()
        heavyImpactGenerator?.prepare()
        selectionGenerator?.prepare()
        notificationGenerator?.prepare()
        
        print("[DEBUG] UIKit触觉生成器初始化完成")
    }
    
    /// 启用或禁用触觉反馈
    func setHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
        print("[DEBUG] 触觉反馈已" + (enabled ? "启用" : "禁用"))
    }
    
    /// 准备触觉生成器，减少使用时的延迟
    func prepareForUse() {
        lightImpactGenerator?.prepare()
        mediumImpactGenerator?.prepare()
        selectionGenerator?.prepare()
    }
    
    /// 播放轻度触觉反馈
    func playLightImpact() {
        guard hapticsEnabled else { return }
        
        // 使用UIKit触觉反馈，避免使用Core Haptics
        lightImpactGenerator?.impactOccurred()
        
        // 重新准备生成器以便下次使用
        lightImpactGenerator?.prepare()
    }
    
    /// 播放中度触觉反馈
    func playMediumImpact() {
        guard hapticsEnabled else { return }
        
        mediumImpactGenerator?.impactOccurred()
        mediumImpactGenerator?.prepare()
    }
    
    /// 播放重度触觉反馈
    func playHeavyImpact() {
        guard hapticsEnabled else { return }
        
        heavyImpactGenerator?.impactOccurred()
        heavyImpactGenerator?.prepare()
    }
    
    /// 播放选择反馈
    func playSelection() {
        guard hapticsEnabled else { return }
        
        selectionGenerator?.selectionChanged()
        selectionGenerator?.prepare()
    }
    
    /// 播放通知反馈
    /// - Parameter type: 通知类型 (.success, .warning, .error)
    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        
        notificationGenerator?.notificationOccurred(type)
        notificationGenerator?.prepare()
    }
}

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
                            // 使用安全的触觉反馈
                            .onChange(of: viewModel.sceneBrightness) { _ in
                                HapticManager.shared.playLightImpact()
                            }
                            
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
                            // 使用安全的触觉反馈
                            .onChange(of: viewModel.sceneBrightness) { _ in
                                HapticManager.shared.playLightImpact()
                            }
                            
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
                    
                    // Debug information toggle
                    Toggle(isOn: $viewModel.showDebugInfo) {
                        Text("显示调试信息")
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding(.horizontal)
                    .onChange(of: viewModel.showDebugInfo) { _ in 
                        // 通知视图模型切换调试信息显示
                        NotificationCenter.default.post(name: .debugInfoToggled, object: nil)
                    }
                    
                    // Haptics enable/disable toggle
                    Toggle(isOn: .init(
                        get: { UserDefaults.standard.bool(forKey: "hapticsEnabled") },
                        set: { newValue in
                            UserDefaults.standard.set(newValue, forKey: "hapticsEnabled")
                            HapticManager.shared.setHapticsEnabled(newValue)
                            
                            // Play feedback only if enabling
                            if newValue {
                                HapticManager.shared.playNotification(.success)
                            }
                        }
                    )) {
                        Text("启用触觉反馈")
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .padding(.horizontal)
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
