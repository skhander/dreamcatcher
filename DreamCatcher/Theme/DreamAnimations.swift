import SwiftUI

struct ShimmerIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : (reduceMotion ? 1 : 0))
            .offset(y: appeared || reduceMotion ? 0 : 6)
            .blur(radius: appeared || reduceMotion ? 0 : 2)
            .animation(reduceMotion ? .default : .easeOut(duration: 0.6).delay(delay), value: appeared)
            .onAppear { appeared = true }
    }
}

struct SymbolGlow: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowing = false
    let active: Bool

    func body(content: Content) -> some View {
        content
            .shadow(
                color: active ? DreamTheme.electricViolet.opacity(reduceMotion ? 0.45 : (glowing ? 0.7 : 0.35)) : .clear,
                radius: active ? 8 : 0
            )
            .animation(active && !reduceMotion ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true) : .default, value: glowing)
            .onAppear {
                if active { glowing = true }
            }
    }
}

struct OrbFloat: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let seed: Double
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .offset(y: reduceMotion ? 0 : (up ? -6 : 6))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 3.5 + seed).repeatForever(autoreverses: true)) {
                    up = true
                }
            }
    }
}

struct DreamFloat: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false

    func body(content: Content) -> some View {
        content
            .offset(y: reduceMotion ? 0 : (floating ? -3 : 3))
            .animation(reduceMotion ? .default : .easeInOut(duration: 4).repeatForever(autoreverses: true), value: floating)
            .onAppear {
                guard !reduceMotion else { return }
                floating = true
            }
    }
}

struct NebulaMicGlow: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let audioLevel: Float
    let idlePulse: Bool

    func body(content: Content) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DreamTheme.sunsetOrange.opacity(0.15 + Double(audioLevel) * 0.35),
                            DreamTheme.electricViolet.opacity(0.12 + Double(audioLevel) * 0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(!reduceMotion && idlePulse ? 1.05 : 1.0)
                .animation(reduceMotion ? .default : .easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: idlePulse)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            DreamTheme.electricViolet.opacity(0.4),
                            DreamTheme.sunsetOrange.opacity(0.35),
                            DreamTheme.tealMist.opacity(0.3),
                            DreamTheme.electricViolet.opacity(0.4)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 130, height: 130)
                .opacity(0.5 + Double(audioLevel) * 0.5)

            content
        }
    }
}

extension View {
    func shimmerIn(delay: Double = 0) -> some View {
        modifier(ShimmerIn(delay: delay))
    }

    func symbolGlow(_ active: Bool) -> some View {
        modifier(SymbolGlow(active: active))
    }

    func orbFloat(seed: Double = 1.0) -> some View {
        modifier(OrbFloat(seed: seed))
    }

    func dreamFloat() -> some View {
        modifier(DreamFloat())
    }

    func nebulaMicGlow(audioLevel: Float, idlePulse: Bool = true) -> some View {
        modifier(NebulaMicGlow(audioLevel: audioLevel, idlePulse: idlePulse))
    }
}
