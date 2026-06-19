//
//  DesignSystem.swift
//  阿默 —— 全息玻璃设计令牌
//
//  全 app 的材质规范集中在这里：圆角阶梯、间距、玻璃填充/描边/阴影。
//  以前各文件里散落着 0.36/0.46/0.55/0.62/0.64 等魔法数，
//  以及 16/20/22/24/28/30 等不统一圆角，现在一律走 Glass 枚举。
//

import SwiftUI

// MARK: - 圆角 / 间距 / 阴影 令牌

enum Glass {
    /// 圆角阶梯：从小到大。一处改，全 app 一致。
    enum Radius {
        static let chip: CGFloat = 14   // 小标签、建议条
        static let row: CGFloat = 16    // 表单行
        static let field: CGFloat = 14  // 输入框
        static let card: CGFloat = 24   // 普通卡片
        static let hero: CGFloat = 28   // 大卡片 / 页头
    }

    /// 间距阶梯。
    enum Space {
        static let s4: CGFloat = 4
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s22: CGFloat = 22   // 页面横向边距
    }

    /// 玻璃描边色 + 线宽（全 app 统一，不再每个文件各写各的）。
    static let stroke = Color.white.opacity(0.76)
    static let strokeThin = Color.white.opacity(0.58)
    static let lineWidth: CGFloat = 1
}

// MARK: - GenUI motion

enum GenUIMotion {
    static let morph = Animation.spring(response: 0.52, dampingFraction: 0.86, blendDuration: 0.08)
    static let quick = Animation.spring(response: 0.30, dampingFraction: 0.84, blendDuration: 0.04)
    static let reveal = Animation.easeOut(duration: 0.28)
}

// MARK: - 玻璃材质层级

/// 玻璃的视觉层级：决定填充浓度、阴影强弱。
/// 把"前景卡片 vs 表单行 vs 浮动按钮"区分开，层次才不糊。
enum GlassTier {
    /// 浮在最前的卡片（每日简报、页头）：填充较实、阴影较重，跳出来。
    case hero
    /// 普通卡片 / 气泡：中等填充。
    case card
    /// 表单行：最淡，读起来像一组而不是一堆飘卡。
    case row
    /// 小元素（chip / 建议 / 输入框）：几乎透明，只靠描边勾勒。
    case inline

    var fillOpacity: Double {
        switch self {
        case .hero: return 0.58
        case .card: return 0.48
        case .row:  return 0.38
        case .inline: return 0.30
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .hero: return 0.070
        case .card: return 0.052
        case .row:  return 0.030
        case .inline: return 0.022
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .hero: return 24
        case .card: return 16
        case .row:  return 8
        case .inline: return 7
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .hero: return 12
        case .card: return 8
        case .row:  return 4
        case .inline: return 4
        }
    }
}

// MARK: - 玻璃表面 modifier

/// 统一的玻璃表面：填充 + 描边 + 阴影。
/// 用 .glassSurface(.card, radius: .card) 一行套上，替代各处手写的
/// .background(.ultraThinMaterial).overlay(stroke).shadow(...) 三连。
struct GlassSurface: ViewModifier {
    let tier: GlassTier
    let radius: CGFloat
    var stroke: Color = Glass.stroke
    var materialOpacity: Double? = nil   // 覆盖 tier.fillOpacity（少数特例用）

    func body(content: Content) -> some View {
        let fill = materialOpacity ?? tier.fillOpacity
        return content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.74)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(Color.white.opacity(fill))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: Glass.lineWidth)
            )
            .shadow(color: .black.opacity(tier.shadowOpacity),
                    radius: tier.shadowRadius, y: tier.shadowY)
    }
}

extension View {
    /// 套一层统一玻璃表面。
    func glassSurface(_ tier: GlassTier,
                      radius: CGFloat,
                      stroke: Color = Glass.stroke,
                      fillOverride: Double? = nil) -> some View {
        modifier(GlassSurface(tier: tier, radius: radius,
                              stroke: stroke, materialOpacity: fillOverride))
    }
}

// MARK: - 文字 scrim

/// 一层极淡的垂直渐变底，垫在浮于彩色背景的文字下，保证任意情绪配色下都清晰。
/// 比给文字加阴影更干净，也不会破坏全息通透感。
struct TextScrim: ViewModifier {
    var strength: Double = 0.55   // 0=透明，1=最强
    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(strength * 0.35),
                    Color.white.opacity(strength * 0.55),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: Glass.Radius.field, style: .continuous))
        )
    }
}

extension View {
    func textScrim(_ strength: Double = 0.55) -> some View {
        modifier(TextScrim(strength: strength))
    }
}

// MARK: - Entrance motion

private struct RevealOnAppear: ViewModifier {
    @State private var visible = false
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 8)
            .onAppear {
                withAnimation(GenUIMotion.reveal.delay(delay)) {
                    visible = true
                }
            }
    }
}

extension View {
    func revealOnAppear(delay: Double = 0) -> some View {
        modifier(RevealOnAppear(delay: delay))
    }
}

// MARK: - App page scaffolding

struct GenUIBackground: View {
    let palette: MoodPalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xF6F8F8),
                    Color(hex: 0xEDF1F2),
                    Color(hex: 0xF8F8F6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                Circle()
                    .fill(Color(hex: 0xF4D6BF).opacity(0.24))
                    .frame(width: w * 0.82, height: w * 0.82)
                    .blur(radius: 60)
                    .offset(x: w * 0.18, y: h * 0.10)

                Circle()
                    .fill(palette.accentSoft.opacity(0.28))
                    .frame(width: w * 0.78, height: w * 0.78)
                    .blur(radius: 62)
                    .offset(x: w * 0.42, y: h * 0.28)

                Circle()
                    .fill(Color(hex: 0xBFD8F5).opacity(0.16))
                    .frame(width: w * 0.86, height: w * 0.86)
                    .blur(radius: 72)
                    .offset(x: -w * 0.36, y: h * 0.58)
            }
            .ignoresSafeArea()

            Color.white.opacity(0.44).ignoresSafeArea()
        }
    }
}

struct RobotPage<Content: View>: View {
    let palette: MoodPalette
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            GenUIBackground(palette: palette)
            ScrollView {
                VStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, Glass.Space.s16)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .tint(Color.black.opacity(0.72))
        .animation(GenUIMotion.morph, value: palette.accent)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct SurfaceSection<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.68))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.black.opacity(0.40))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                        .fill(Color.white.opacity(0.50))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: Glass.Radius.hero, style: .continuous)
                .stroke(Color.white.opacity(0.74), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.055), radius: 16, y: 8)
        .revealOnAppear()
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.055))
            .frame(height: 1)
    }
}

struct IconActionButton: View {
    let systemName: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(enabled ? Color.black.opacity(0.66) : Color.black.opacity(0.28))
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.56), in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.74), lineWidth: 1))
                .shadow(color: .black.opacity(0.045), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct MoonAvatarBadge: View {
    var size: CGFloat = 86
    var showGlow: Bool = true
    var showMoonMark: Bool = true
    var imageName: String = "AssistantFemale"

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xDDEBFF).opacity(0.84),
                                Color(hex: 0xBCA7FF).opacity(0.36),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.16,
                            endRadius: size * 0.78
                        )
                    )
                    .frame(width: size * 1.55, height: size * 1.55)
                    .blur(radius: size * 0.14)
            }

            Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .offset(y: size * 0.12)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.96),
                                    Color(hex: 0xBFE7FF).opacity(0.82),
                                    Color(hex: 0xC7B5FF).opacity(0.86)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.2, size * 0.025)
                        )
                )
                .shadow(color: Color(hex: 0x83CFFF).opacity(0.26), radius: size * 0.18, y: size * 0.08)
                .shadow(color: .black.opacity(0.12), radius: size * 0.16, y: size * 0.08)

            Circle()
                .stroke(Color.white.opacity(0.36), lineWidth: 1)
                .frame(width: size * 1.18, height: size * 1.18)

            if showMoonMark {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: size * 0.15, weight: .semibold))
                    .foregroundStyle(Color.white, Color(hex: 0x97BFFF))
                    .frame(width: size * 0.34, height: size * 0.34)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.82), lineWidth: 1))
                    .offset(x: size * 0.34, y: size * 0.34)
                    .shadow(color: .black.opacity(0.12), radius: size * 0.08, y: size * 0.03)
            }
        }
        .frame(width: size * 1.48, height: size * 1.48)
        .accessibilityLabel("阿默头像")
    }
}

// MARK: - Siri-like communication surfaces

struct SiriCommunicationHero: View {
    enum Visual {
        case assistantAvatar
        case personSignal
    }

    let title: String
    let subtitle: String
    let chips: [String]
    let palette: MoodPalette
    var visual: Visual = .assistantAvatar
    var avatarImageName: String = "AssistantFemale"

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    if visual == .assistantAvatar {
                        // 给左侧半身像留位，标题文字从这之后开始，避免被立绘压住
                        Color.clear.frame(width: 118, height: 1)
                    } else {
                        PersonSignalHero(palette: palette)
                            .frame(width: 132, height: 132)
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text(title)
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(Color.black.opacity(0.74))
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.black.opacity(0.42))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.52))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.54), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.76), lineWidth: 1))
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.68),
                                        palette.accentSoft.opacity(0.24),
                                        Color(hex: 0xF4D6BF).opacity(0.20),
                                        Color.white.opacity(0.40)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(Color.white.opacity(0.64), lineWidth: 1)
                    )
            }
            .shadow(color: .black.opacity(0.075), radius: 24, y: 12)

            // 半身头像：左侧和顶部凸出框外
            if visual == .assistantAvatar {
                AssistantBustHero(palette: palette, imageName: avatarImageName)
                    .offset(x: -6, y: -42)
            }
        }
        .padding(.top, 52)   // 给探出的头预留空间，避免被导航栏裁掉
        .revealOnAppear()
    }

}

struct AssistantBustHero: View {
    let palette: MoodPalette
    let imageName: String

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(palette.accentSoft.opacity(0.34))
                    .frame(width: 132, height: 132)
                    .blur(radius: 22)
                    .offset(y: 16)

                ForEach(0..<3, id: \.self) { index in
                    let pulse = 1 + 0.035 * sin(t * (1.25 + Double(index) * 0.22) + Double(index))
                    Circle()
                        .stroke(
                            palette.orb[index % palette.orb.count].opacity(0.34),
                            lineWidth: index == 0 ? 7 : 4
                        )
                        .frame(width: 104 + CGFloat(index) * 17, height: 104 + CGFloat(index) * 17)
                        .scaleEffect(pulse)
                        .offset(y: 18)
                }

                Image(imageName)
                    .resizable()
                    .aspectRatio(1024.0 / 1536.0, contentMode: .fit)  // 贴合真实图 2:3，不留白不变形
                    .frame(width: 138, height: 207)
                    // 只在底部融入卡片，头、脸、两侧都保持清晰，让人物清楚地“站出来”
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0.0),
                                .init(color: .black, location: 0.80),
                                .init(color: .black.opacity(0.85), location: 0.90),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: palette.accent.opacity(0.28), radius: 24, y: 10)
                    .shadow(color: .black.opacity(0.18), radius: 22, y: 12)
                    .scaleEffect(1 + 0.012 * sin(t * 1.45))
                    .offset(x: -4, y: -46)

                Image(systemName: "moon.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white, Color(hex: 0x8EBFFF))
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.84), lineWidth: 1))
                    .offset(x: 42, y: 42)
            }
            .frame(width: 152, height: 190)
        }
        .accessibilityHidden(true)
    }
}

struct PersonSignalHero: View {
    let palette: MoodPalette

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(palette.accentSoft.opacity(0.28))
                    .frame(width: 116, height: 116)
                    .blur(radius: 18)

                ForEach(0..<3, id: \.self) { index in
                    PersonSignalRing(palette: palette, index: index, time: t)
                }

                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.black.opacity(0.58))
                    .frame(width: 82, height: 82)
                    .background(Color.white.opacity(0.62), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.86), lineWidth: 1))
                    .shadow(color: .black.opacity(0.08), radius: 14, y: 7)
            }
            .frame(width: 132, height: 132)
        }
        .accessibilityHidden(true)
    }
}

private struct PersonSignalRing: View {
    let palette: MoodPalette
    let index: Int
    let time: TimeInterval

    private var ringSize: CGFloat {
        88 + CGFloat(index) * 18
    }

    private var pulse: CGFloat {
        let speed = 1.05 + Double(index) * 0.2
        return 1 + CGFloat(0.026 * sin(time * speed + Double(index)))
    }

    var body: some View {
        Circle()
            .stroke(ringColor, lineWidth: index == 0 ? 6 : 3)
            .frame(width: ringSize, height: ringSize)
            .scaleEffect(pulse)
    }

    private var ringColor: Color {
        palette.orb[(index + 1) % palette.orb.count].opacity(0.28)
    }
}

struct SiriWaveView: View {
    let palette: MoodPalette

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let baseRadius = min(size.width, size.height) * 0.23

                for index in 0..<4 {
                    let progress = Double(index) / 4.0
                    let wave = 1.0 + 0.09 * sin(t * (1.4 + progress) + progress * 5.2)
                    let radius = baseRadius * CGFloat(1.0 + progress * 0.76) * CGFloat(wave)
                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    var path = Path(ellipseIn: rect)
                    let color = palette.orb[index % palette.orb.count].opacity(0.42 - progress * 0.05)
                    canvas.stroke(path, with: .color(color), lineWidth: 9 - CGFloat(index) * 1.4)

                    path = Path(ellipseIn: rect.insetBy(dx: radius * 0.16, dy: radius * 0.16))
                    canvas.stroke(path, with: .color(Color.white.opacity(0.42)), lineWidth: 1)
                }

                for index in 0..<3 {
                    let x = center.x + CGFloat(cos(t * (0.8 + Double(index) * 0.22) + Double(index))) * size.width * 0.16
                    let y = center.y + CGFloat(sin(t * (0.9 + Double(index) * 0.18) + Double(index) * 1.7)) * size.height * 0.16
                    let dotRect = CGRect(x: x - 8, y: y - 8, width: 16, height: 16)
                    canvas.fill(Path(ellipseIn: dotRect), with: .color(palette.orb[(index + 1) % palette.orb.count].opacity(0.55)))
                }
            }
            .background {
                ZStack {
                    Circle()
                        .fill(palette.accentSoft.opacity(0.44))
                        .blur(radius: 16)
                    Circle()
                        .fill(Color.white.opacity(0.52))
                        .frame(width: 58, height: 58)
                        .overlay(Circle().stroke(Color.white.opacity(0.86), lineWidth: 1))
                }
            }
            .scaleEffect(1 + 0.025 * sin(t * 1.5))
        }
        .accessibilityHidden(true)
    }
}
