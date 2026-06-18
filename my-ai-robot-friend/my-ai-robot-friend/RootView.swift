//
//  RootView.swift
//  阿默 —— 四个页签：聊天 / 阿默 / 记忆 / 设置
//

import SwiftUI

struct RootView: View {
    @StateObject private var store = ChatStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection = RootView.initialTab()

    private static func initialTab() -> Int {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--tab"), i + 1 < args.count {
            switch args[i + 1] {
            case "profile": return 1
            case "me": return 2
            case "memory": return 3
            case "settings": return 4
            default: return 0
            }
        }
        return 0
    }

    var body: some View {
        TabView(selection: $selection) {
            ChatView(store: store)
                .tabItem { Label("聊天", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(0)
            ProfileView(store: store)
                .tabItem { Label(store.persona.name, systemImage: "sparkles") }
                .tag(1)
            MeView(store: store)
                .tabItem { Label("我", systemImage: "person.fill") }
                .tag(2)
            MemoryView(store: store)
                .tabItem { Label("记忆", systemImage: "brain.head.profile") }
                .tag(3)
            SettingsView(store: store)
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(.primary)
        .preferredColorScheme(.light)
        .task {
            await NotificationManager.shared.requestAuthorization()
            store.rescheduleNotifications()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { store.rescheduleNotifications() }
        }
    }
}

/// 在全息背景上铺一个透明 Form，行用玻璃材质——配置类页面统一用它。
struct GlassFormBackground: ViewModifier {
    let palette: MoodPalette
    func body(content: Content) -> some View {
        ZStack {
            IridescentBackground(palette: palette)
            content
                .scrollContentBackground(.hidden)
        }
    }
}

extension View {
    func glassForm(_ palette: MoodPalette) -> some View {
        modifier(GlassFormBackground(palette: palette))
    }

    /// 玻璃行背景
    func glassRow() -> some View {
        listRowBackground(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.4), lineWidth: 1))
                .padding(.vertical, 2)
        )
    }
}
