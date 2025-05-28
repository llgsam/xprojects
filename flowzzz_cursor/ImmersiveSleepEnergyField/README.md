# 沉浸式睡前能量场 (Immersive Sleep Energy Field)

一个基于 iOS/visionOS 的沉浸式睡前氛围应用，当前重点实现**"萤火虫之梦"**场景。

## 项目概述

该应用提供沉浸式、动态生成、根据情绪和音乐自动播放的睡前氛围场景，帮助用户平复情绪，安心睡眠。核心体验是空间感和粒子效果。

### 核心特性

- 🌟 **萤火虫之梦场景**: 动态粒子系统模拟萤火虫群
- 🎵 **音乐驱动**: 背景音乐与视觉效果同步
- 💫 **情绪脚本**: 基于时间轴的情绪强度和颜色变化
- 🌙 **白天/夜晚模式**: 不同时间段的视觉体验
- ⌚ **Apple Watch 支持**: 远程控制播放和音量
- 📱 **多设备支持**: iPhone (主), Apple Watch (控制), VisionPro (兼容)

## 技术架构

### 技术栈
- **语言**: Swift
- **UI 框架**: SwiftUI
- **3D 渲染**: RealityKit (粒子系统和空间计算)
- **音频处理**: AVFoundation
- **设备间通信**: WatchConnectivity

### 架构模式
采用 MVVM (Model-View-ViewModel) 模式

## 项目结构

```
ImmersiveSleepEnergyField/
├── Models/
│   └── ImmersiveSceneType.swift          # 场景类型定义和数据结构
├── Services/
│   ├── MusicService.swift                # 音乐播放服务
│   ├── EmotionScriptService.swift        # 情绪脚本服务
│   └── WatchConnectivityService.swift    # Watch 连接服务
├── ViewModels/
│   └── SceneViewModel.swift              # 核心业务逻辑
├── Views/
│   ├── ContentView.swift                 # 主界面
│   ├── ImmersiveSceneView.swift          # 沉浸式场景视图
│   └── RealityViewContainer.swift        # RealityKit 容器
├── Resources/
│   └── firefly_emotion_script.json       # 萤火虫情绪脚本
└── ImmersiveSleepEnergyFieldApp.swift    # 应用入口
```

## 核心组件说明

### 1. SceneViewModel
- 管理当前场景状态、加载、切换
- 协调音乐、情绪脚本和视觉效果
- 处理用户交互和 Watch 通信

### 2. 粒子系统 (RealityKit)
- 萤火虫光点粒子效果
- 动态颜色和强度调整
- 白天/夜晚模式适配

### 3. 情绪脚本系统
- 基于时间轴的情绪强度变化 (0.0-1.0)
- 颜色渐变过渡
- 循环播放支持

### 4. 音乐服务
- 背景音乐循环播放
- 音量控制
- 音频分析接口 (预留)

## 资源文件要求

在 Xcode 项目中添加以下资源文件到 Bundle Resources：

### 必需文件
1. **FireflyDaytime.usdz** - 萤火虫白天场景 3D 模型
2. **FireflyNighttime.usdz** - 萤火虫夜晚场景 3D 模型
3. **firefly_music.mp3** - 萤火虫场景背景音乐
4. **firefly_emotion_script.json** - 情绪脚本 (已包含示例)

### 资源文件说明
- **USDZ 模型**: 极简几何体，主要作为粒子发射器载体
- **音乐文件**: 支持循环播放的舒缓音乐
- **情绪脚本**: JSON 格式，定义时间轴上的情绪强度和颜色

## 开发设置

### 1. Xcode 项目配置
- 最低部署目标: iOS 15.0+
- 支持 ARKit
- 启用 WatchConnectivity

### 2. 权限配置
- 相机权限 (ARKit 需要)
- 音频播放权限

### 3. 依赖框架
- SwiftUI
- RealityKit
- ARKit
- AVFoundation
- WatchConnectivity

## 使用说明

### 基本操作
1. **播放/暂停**: 点击中央播放按钮
2. **音量调节**: 使用音量滑块
3. **模式切换**: 点击白天/夜晚按钮
4. **Watch 控制**: 通过 Apple Watch 远程控制

### 视觉效果
- **萤火虫粒子**: 根据情绪强度动态调整数量和亮度
- **颜色变化**: 跟随情绪脚本进行渐变过渡
- **音乐同步**: 粒子大小微调响应音乐节拍 (预留功能)

## 扩展计划

### 未来场景
- **星河之愿**: 星空粒子效果
- **能量水晶**: 水晶光效场景

### 功能增强
- 实时音频分析
- 自定义情绪脚本
- 更多粒子效果
- VisionPro 专属体验

## 开发注意事项

1. **性能优化**: 粒子数量需要根据设备性能调整
2. **内存管理**: 及时释放 RealityKit 资源
3. **电池优化**: 合理使用 CADisplayLink 更新频率
4. **兼容性**: 确保在不同 iOS 设备上的表现一致

## 故障排除

### 常见问题
1. **粒子不显示**: 检查 RealityKit 权限和 ARKit 支持
2. **音乐不播放**: 确认音频文件已添加到 Bundle Resources
3. **Watch 连接失败**: 检查 WatchConnectivity 配置

### 调试建议
- 使用 Xcode 的 Reality Composer 预览 USDZ 模型
- 检查控制台日志中的资源加载信息
- 验证情绪脚本 JSON 格式正确性

## 许可证

[添加适当的许可证信息]

## 贡献

[添加贡献指南] 