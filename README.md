# My AI Robot Friend 🤖

一个基于 SwiftUI 的 AI 聊天机器人应用，支持多平台（iOS/iPadOS/macOS）。

## 功能特点

- 💬 与 AI 朋友聊天解闷
- 🧠 智能记忆系统，记住对话内容
- 🎙️ 语音输入支持
- 👤 个性化设置（昵称、头像）
- 🎨 渐变彩虹背景动画
- 📱 支持 iPhone、iPad、Mac

## 技术栈

- SwiftUI
- DeepSeek API
- Swift Concurrency (async/await)

## 项目结构

```
my-ai-robot-friend/
├── my-ai-robot-friend/
│   ├── Views/
│   │   ├── ContentView.swift      # 主聊天界面
│   │   ├── MemoryView.swift       # 记忆管理
│   │   ├── MeView.swift          # 个人中心
│   │   ├── SettingsView.swift     # 设置
│   │   ├── ProfileView.swift      # 资料编辑
│   │   ├── OnboardingView.swift   # 新手引导
│   │   └── DesignSystem.swift     # 设计系统
│   ├── Services/
│   │   ├── ChatStore.swift        # 聊天数据管理
│   │   ├── DeepSeekService.swift  # AI 接口
│   │   ├── Speaker.swift          # 语音合成
│   │   └── VoiceInputController.swift # 语音输入
│   ├── Models/
│   │   └── Models.swift           # 数据模型
│   └── Theme.swift               # 主题配置
└── README.md
```

## 如何使用

1. 用 Xcode 打开项目
2. 配置 DeepSeek API Key
3. 运行到目标设备

## 许可证

MIT License
