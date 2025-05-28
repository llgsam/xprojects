# 沉浸式睡前能量场 (Immersive Sleep Energy Field)

一个使用 Swift、SwiftUI 和 RealityKit 构建的沉浸式睡眠辅助应用，提供动态生成的、根据情绪和音乐自动播放的睡前氛围场景。

## 项目概述

本应用旨在提供沉浸式、动态生成的睡前氛围场景，帮助用户平复情绪，安心睡眠。当前版本实现了"萤火虫之梦"场景，未来将支持"星河之愿"和"能量水晶"场景。

### 核心功能

- 沉浸式 3D 萤火虫场景，使用 RealityKit 渲染
- 基于情绪脚本的动态场景变化
- 日/夜模式切换
- 背景音乐播放与控制
- Apple Watch 控制支持（基础架构）

## 技术栈

- 语言: Swift
- UI 框架: SwiftUI
- 3D 渲染: RealityKit
- 音频处理: AVFoundation
- 设备间通信: WatchConnectivity

## 项目结构

```
ImmersiveSleepEnergyField/
├── Models/              # 数据模型
├── Services/            # 服务层
├── ViewModels/          # 视图模型
├── Views/               # UI 视图
├── Resources/           # 资源文件
```

## 使用说明

### 必需资源

在运行应用前，请确保以下资源文件已添加到项目中：

1. 3D 模型:
   - `FireflyDaytime.usdz` - 白天萤火虫场景模型
   - `FireflyNighttime.usdz` - 夜晚萤火虫场景模型

2. 音频文件:
   - `firefly_music.mp3` - 萤火虫场景背景音乐

3. 情绪脚本:
   - `firefly_emotion_script.json` - 定义萤火虫场景情绪变化

> 注意：如果没有添加这些资源文件，应用会使用内置的默认配置运行，但某些功能可能受限。

### 控制界面

- 播放/暂停按钮：控制背景音乐播放
- 音量滑块：调整背景音乐音量
- 日/夜模式切换：切换场景的日间和夜间模式
- 场景选择（预留）：当前仅支持萤火虫场景

## 开发指南

### 添加新场景

1. 在 `ImmersiveSceneType.swift` 中添加新的场景类型
2. 创建相应的 USDZ 模型文件
3. 在 `SceneViewModel.swift` 中实现场景配置方法
4. 创建相应的情绪脚本 JSON 文件

### 自定义情绪脚本

情绪脚本是 JSON 格式的文件，定义了场景随时间的情绪变化：

```json
{
    "name": "脚本名称",
    "description": "脚本描述",
    "duration": 600,
    "keyPoints": [
        {
            "timeOffset": 0,
            "emotionIntensity": 0.3,
            "targetColorHex": "#5D88F0"
        },
        ...
    ]
}
```

## Apple Watch 支持

当前版本包含了 Apple Watch 通信的基础架构，支持以下功能：

- 播放/暂停控制
- 音量调节
- 场景切换
- 日/夜模式切换

要完全启用 Apple Watch 支持，需要在 Xcode 中添加 Watch App 目标并实现相应的 UI。
