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
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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
            GenUIBackground(palette: palette)
            content
                .scrollContentBackground(.hidden)
                .listSectionSpacing(16)
        }
    }
}

extension View {
    func glassForm(_ palette: MoodPalette) -> some View {
        modifier(GlassFormBackground(palette: palette))
    }

    /// 玻璃行背景：同一区块内的行收紧、柔化，读起来像一组而不是一堆飘卡。
    func glassRow() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .listRowBackground(
                RoundedRectangle(cornerRadius: Glass.Radius.row, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: Glass.Radius.row, style: .continuous)
                        .fill(Color.white.opacity(0.52)))
                    .overlay(RoundedRectangle(cornerRadius: Glass.Radius.row, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 0.75))
                    .shadow(color: .black.opacity(0.035), radius: 8, y: 4)
                    .padding(.vertical, 1.5)
            )
    }

    func glassFieldBackground() -> some View {
        self
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.58)))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(0.025), radius: 8, y: 4)
    }
}

struct GlassPageHeader: View {
    let imageName: String?
    let systemImage: String?
    let title: String
    let subtitle: String
    let palette: MoodPalette

    init(imageName: String? = nil, systemImage: String? = nil, title: String, subtitle: String, palette: MoodPalette) {
        self.imageName = imageName
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.palette = palette
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(palette.accentSoft.opacity(0.38))
                    .frame(width: 66, height: 66)
                    .blur(radius: 10)
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.62))
                        .frame(width: 54, height: 54)
                        .background(Color.white.opacity(0.58), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 1))
                }
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.72))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.42))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.46))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 18, y: 9)
        .revealOnAppear()
    }
}
