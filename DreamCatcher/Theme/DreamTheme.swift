import SwiftUI

enum DreamTheme {
    // Sleep-quiet palette — indigo base, cream foreground, lilac + peach accents
    static let nightIndigo = Color(red: 0.08, green: 0.11, blue: 0.22)
    static let cosmicPlum = nightIndigo
    static let midnightBlue = Color(red: 0.06, green: 0.09, blue: 0.18)
    static let memoryFog = Color(red: 0.14, green: 0.17, blue: 0.28)
    static let dreamBlue = Color(red: 0.18, green: 0.24, blue: 0.40)
    static let deepSpace = nightIndigo

    static let electricViolet = Color(red: 0.55, green: 0.40, blue: 0.82)
    static let slateLilac = Color(red: 0.62, green: 0.66, blue: 0.82)
    static let lavender = slateLilac
    static let softGlow = Color(red: 0.74, green: 0.74, blue: 0.92)

    static let sunsetOrange = Color(red: 0.92, green: 0.55, blue: 0.38)
    static let peachGlow = Color(red: 0.96, green: 0.80, blue: 0.66)
    static let goldDust = Color(red: 0.85, green: 0.78, blue: 0.58)

    static let tealMist = Color(red: 0.36, green: 0.58, blue: 0.66)
    static let creamDream = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let moonlight = creamDream
    static let pearlMist = Color(red: 0.94, green: 0.93, blue: 0.88)
    static let cloudShadow = Color(red: 0.40, green: 0.42, blue: 0.58)

    static var nebulaGradient: LinearGradient {
        LinearGradient(
            colors: [nightIndigo, midnightBlue, dreamBlue.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var bedsideGradient: LinearGradient {
        LinearGradient(
            colors: [nightIndigo, midnightBlue.opacity(0.95), memoryFog],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // Kept for small-scale accents (e.g. timeline dream nodes). Avoid using on large surfaces.
    static var iridescentBorder: AngularGradient {
        AngularGradient(
            colors: [
                electricViolet.opacity(0.45),
                peachGlow.opacity(0.40),
                tealMist.opacity(0.35),
                slateLilac.opacity(0.35),
                electricViolet.opacity(0.45)
            ],
            center: .center
        )
    }

    static func emotionColor(_ emotion: DreamEmotion) -> Color {
        switch emotion {
        case .longing: return Color(red: 0.65, green: 0.55, blue: 0.88)
        case .grief: return Color(red: 0.42, green: 0.50, blue: 0.72)
        case .freedom: return Color(red: 0.42, green: 0.78, blue: 0.82)
        case .transition: return Color(red: 0.70, green: 0.62, blue: 0.82)
        case .avoidance: return Color(red: 0.38, green: 0.38, blue: 0.58)
        case .desire: return Color(red: 0.92, green: 0.55, blue: 0.58)
        case .shame: return Color(red: 0.52, green: 0.40, blue: 0.52)
        case .wonder: return Color(red: 0.55, green: 0.72, blue: 0.98)
        case .peace: return Color(red: 0.48, green: 0.72, blue: 0.68)
        case .fear: return Color(red: 0.45, green: 0.40, blue: 0.62)
        }
    }
}

struct DreamCard: ViewModifier {
    var floating: Bool = false

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(DreamTheme.pearlMist.opacity(0.07))
            .background(DreamTheme.nightIndigo.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(DreamTheme.creamDream.opacity(0.12), lineWidth: 0.5)
            )
            .modifier(FloatingOptional(enabled: floating))
    }
}

private struct FloatingOptional: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let enabled: Bool
    @State private var floating = false

    func body(content: Content) -> some View {
        content
            .offset(y: enabled && !reduceMotion ? (floating ? -3 : 3) : 0)
            .animation(enabled && !reduceMotion ? .easeInOut(duration: 4).repeatForever(autoreverses: true) : .default, value: floating)
            .onAppear {
                guard enabled, !reduceMotion else { return }
                floating = true
            }
    }
}

struct GlassCard: ViewModifier {
    var floating: Bool = false

    func body(content: Content) -> some View {
        content.modifier(DreamCard(floating: floating))
    }
}

extension View {
    func dreamCard(floating: Bool = false) -> some View {
        modifier(DreamCard(floating: floating))
    }

    func glassCard(floating: Bool = false) -> some View {
        modifier(GlassCard(floating: floating))
    }
}

struct BreathingPulse: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing && !reduceMotion ? 1.0 + intensity * 0.1 : 1.0)
            .opacity(isPulsing && !reduceMotion ? 1.0 : 0.88)
            .shadow(color: DreamTheme.electricViolet.opacity(isPulsing ? 0.35 : 0.15), radius: isPulsing ? 16 : 8)
            .animation(
                reduceMotion ? .default : .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

extension View {
    func breathingPulse(intensity: Double = 1.0) -> some View {
        modifier(BreathingPulse(intensity: intensity))
    }
}
