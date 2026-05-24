import SwiftUI

enum DreamscapeIntensity {
    case standard
    case bedside
    case deep
    /// Pure starfield. No clouds, denser stars, calmer drift. For content-heavy
    /// screens like Timeline where clouds compete with foreground content.
    case celestial

    var starCount: Int {
        switch self {
        case .standard: return 50
        case .bedside: return 30
        case .deep: return 40
        case .celestial: return 110
        }
    }

    var motionScale: Double {
        switch self {
        case .standard: return 1.0
        case .bedside: return 0.45
        case .deep: return 0.7
        case .celestial: return 0.6
        }
    }

    var cloudOpacity: Double {
        switch self {
        case .standard: return 0.34
        case .bedside: return 0.22
        case .deep: return 0.28
        case .celestial: return 0
        }
    }

    var horizonOpacity: Double {
        switch self {
        case .standard: return 0.18
        case .bedside: return 0.10
        case .deep: return 0.14
        case .celestial: return 0.05
        }
    }
}

struct StarSeed: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let baseOpacity: Double
    let depth: Int
    let twinkleOffset: Double
}

private struct CloudBump {
    let dx: CGFloat
    let dy: CGFloat
    let r: CGFloat
}

private struct CloudShape {
    let bumps: [CloudBump]
    let baseWidth: CGFloat
}

private enum CloudShapeLibrary {
    // Wide, low anchor. Definite flat-ish bottom, a tall cresting peak left of center.
    static let anchor = CloudShape(bumps: [
        CloudBump(dx: -130, dy: 22, r: 32),
        CloudBump(dx: -88, dy: 2, r: 48),
        CloudBump(dx: -38, dy: -26, r: 60),
        CloudBump(dx: 14, dy: -36, r: 56),
        CloudBump(dx: 64, dy: -16, r: 52),
        CloudBump(dx: 112, dy: 4, r: 44),
        CloudBump(dx: 152, dy: 22, r: 32),
        CloudBump(dx: -50, dy: 28, r: 40),
        CloudBump(dx: 56, dy: 30, r: 44)
    ], baseWidth: 300)

    // Mid-band layered cumulus. More horizontal, two cresting peaks.
    static let layered = CloudShape(bumps: [
        CloudBump(dx: -86, dy: 14, r: 28),
        CloudBump(dx: -46, dy: -8, r: 44),
        CloudBump(dx: -4, dy: -20, r: 50),
        CloudBump(dx: 42, dy: -12, r: 46),
        CloudBump(dx: 86, dy: 6, r: 38),
        CloudBump(dx: -22, dy: 22, r: 36),
        CloudBump(dx: 34, dy: 24, r: 38)
    ], baseWidth: 220)

    // Distant wisp, almost horizon-line.
    static let wisp = CloudShape(bumps: [
        CloudBump(dx: -42, dy: 8, r: 22),
        CloudBump(dx: -16, dy: -10, r: 30),
        CloudBump(dx: 14, dy: -12, r: 28),
        CloudBump(dx: 42, dy: 4, r: 24),
        CloudBump(dx: 0, dy: 16, r: 26)
    ], baseWidth: 110)
}

private struct CloudSeed {
    let shape: CloudShape
    let yFrac: CGFloat
    let baseXFrac: CGFloat
    let scale: CGFloat
    let driftAmplitude: CGFloat
    let driftSpeed: Double
    let opacityMultiplier: Double
}

struct DreamscapeBackground: View {
    var intensity: DreamscapeIntensity = .standard
    var audioLevel: Float = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    private var activeStars: [StarSeed] {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return stars.enumerated().compactMap { $0.offset.isMultiple(of: 2) ? $0.element : nil }
        }
        return stars
    }

    private let stars: [StarSeed]

    // Banked sky: large anchor cloud + mid-tier layered clouds + distant wisps on the horizon.
    // Ordered back-to-front so distant wisps render under closer clouds.
    private let clouds: [CloudSeed] = [
        CloudSeed(shape: CloudShapeLibrary.wisp, yFrac: 0.38, baseXFrac: 0.08, scale: 0.55, driftAmplitude: 0.10, driftSpeed: 0.026, opacityMultiplier: 0.55),
        CloudSeed(shape: CloudShapeLibrary.wisp, yFrac: 0.42, baseXFrac: 0.70, scale: 0.65, driftAmplitude: 0.09, driftSpeed: 0.022, opacityMultiplier: 0.65),
        CloudSeed(shape: CloudShapeLibrary.layered, yFrac: 0.52, baseXFrac: 0.32, scale: 0.85, driftAmplitude: 0.07, driftSpeed: 0.018, opacityMultiplier: 0.80),
        CloudSeed(shape: CloudShapeLibrary.layered, yFrac: 0.66, baseXFrac: 0.18, scale: 1.05, driftAmplitude: 0.06, driftSpeed: 0.014, opacityMultiplier: 0.92),
        CloudSeed(shape: CloudShapeLibrary.layered, yFrac: 0.60, baseXFrac: 0.62, scale: 0.95, driftAmplitude: 0.07, driftSpeed: 0.016, opacityMultiplier: 0.88),
        CloudSeed(shape: CloudShapeLibrary.anchor, yFrac: 0.78, baseXFrac: 0.78, scale: 1.30, driftAmplitude: 0.05, driftSpeed: 0.011, opacityMultiplier: 1.0)
    ]

    init(intensity: DreamscapeIntensity = .standard, audioLevel: Float = 0) {
        self.intensity = intensity
        self.audioLevel = audioLevel
        var generated: [StarSeed] = []
        for i in 0..<intensity.starCount {
            let depth = i % 3
            generated.append(StarSeed(
                id: i,
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                radius: CGFloat([0.6, 1.0, 1.6, 2.2][i % 4]),
                baseOpacity: Double.random(in: 0.25...0.95),
                depth: depth,
                twinkleOffset: Double.random(in: 0...(Double.pi * 2))
            ))
        }
        self.stars = generated
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                animatedBaseGradient

                horizonGlow(size: geo.size)

                if reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled {
                    if intensity.cloudOpacity > 0 {
                        staticCloudCanvas(size: geo.size)
                    }
                    staticStarCanvas(size: geo.size)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate * intensity.motionScale
                        if intensity.cloudOpacity > 0 {
                            cloudCanvas(size: geo.size, time: t)
                        }
                        starCanvas(size: geo.size, time: t)
                    }
                }

                vignette(size: geo.size)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 45).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }

    private var animatedBaseGradient: some View {
        LinearGradient(
            colors: [
                DreamTheme.nightIndigo,
                DreamTheme.midnightBlue,
                DreamTheme.dreamBlue.opacity(0.65 + Double(audioLevel) * 0.10),
                DreamTheme.nightIndigo.opacity(0.92)
            ],
            startPoint: phase < 0.5 ? .topLeading : .top,
            endPoint: phase < 0.5 ? .bottomTrailing : .bottom
        )
        .animation(.easeInOut(duration: 45).repeatForever(autoreverses: true), value: phase)
    }

    private func horizonGlow(size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [
                    DreamTheme.peachGlow.opacity(intensity.horizonOpacity),
                    DreamTheme.peachGlow.opacity(intensity.horizonOpacity * 0.35),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 1.05),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.75
            )
            .blendMode(.plusLighter)
            .opacity(0.7)

            LinearGradient(
                colors: [
                    Color.clear,
                    DreamTheme.dreamBlue.opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
    }

    private func cloudCanvas(size: CGSize, time: Double) -> some View {
        Canvas { context, canvasSize in
            drawClouds(context: &context, size: canvasSize, time: time)
        }
        .blur(radius: 5)
        .allowsHitTesting(false)
    }

    private func staticCloudCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            drawClouds(context: &context, size: canvasSize, time: 0)
        }
        .blur(radius: 5)
        .allowsHitTesting(false)
    }

    private func drawClouds(context: inout GraphicsContext, size: CGSize, time: Double) {
        for cloud in clouds {
            let drift = sin(time * cloud.driftSpeed) * Double(cloud.driftAmplitude)
            let centerX = (Double(cloud.baseXFrac) + drift) * Double(size.width)
            let centerY = Double(cloud.yFrac) * Double(size.height)
            let center = CGPoint(x: centerX, y: centerY)
            let opacity = intensity.cloudOpacity * cloud.opacityMultiplier
            drawCumulus(context: &context, shape: cloud.shape, center: center, scale: cloud.scale, opacity: opacity)
        }
    }

    // Hokusai-style cumulus:
    //   1. Soft mauve ground-shadow underneath (cloud "sitting" on the sky).
    //   2. Outline pass — every bump drawn slightly larger in slate-lilac.
    //   3. Body pass — every bump drawn at true size in cream. The outline only
    //      reads where the larger bumps protrude past the smaller body, so the
    //      cloud gets a unified silhouette stroke instead of a per-bump ring.
    //   4. Warm pearl highlight along the upper crest.
    private func drawCumulus(context: inout GraphicsContext, shape: CloudShape, center: CGPoint, scale: CGFloat, opacity: Double) {
        let outlineInset: CGFloat = 2.0
        let baseWidth = shape.baseWidth * scale

        let shadowRect = CGRect(
            x: center.x - baseWidth * 0.55,
            y: center.y + 26 * scale,
            width: baseWidth * 1.1,
            height: 30 * scale
        )
        context.fill(
            Path(ellipseIn: shadowRect),
            with: .color(DreamTheme.cloudShadow.opacity(opacity * 0.60))
        )

        for bump in shape.bumps {
            let r = bump.r * scale + outlineInset
            let rect = CGRect(
                x: center.x + bump.dx * scale - r,
                y: center.y + bump.dy * scale - r,
                width: r * 2,
                height: r * 2
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(DreamTheme.cloudShadow.opacity(opacity * 0.85))
            )
        }

        for bump in shape.bumps {
            let r = bump.r * scale
            let rect = CGRect(
                x: center.x + bump.dx * scale - r,
                y: center.y + bump.dy * scale - r,
                width: r * 2,
                height: r * 2
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(DreamTheme.creamDream.opacity(opacity))
            )
        }

        // Warm dawn highlight cresting the upper bumps.
        for bump in shape.bumps where bump.dy < -10 {
            let r = bump.r * scale
            let highlightRect = CGRect(
                x: center.x + bump.dx * scale - r * 0.7,
                y: center.y + bump.dy * scale - r * 0.95,
                width: r * 1.4,
                height: r * 0.55
            )
            context.fill(
                Path(ellipseIn: highlightRect),
                with: .color(DreamTheme.peachGlow.opacity(opacity * 0.45))
            )
        }
    }

    private func starCanvas(size: CGSize, time: Double) -> some View {
        Canvas { context, canvasSize in
            drawStars(context: &context, size: canvasSize, time: time, animated: true)
        }
        .allowsHitTesting(false)
    }

    private func staticStarCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            drawStars(context: &context, size: canvasSize, time: 0, animated: false)
        }
        .allowsHitTesting(false)
    }

    private func drawStars(context: inout GraphicsContext, size: CGSize, time: Double, animated: Bool) {
        for star in activeStars {
            // Stars barely drift — they breathe more than they move.
            let speed = [1.5, 2.5, 4.0][star.depth] * intensity.motionScale
            var y = star.y * size.height
            if animated {
                y = (y + CGFloat(time * speed)).truncatingRemainder(dividingBy: size.height + 20) - 10
            }

            var opacity = star.baseOpacity
            // Twinkle only in the upper sky — keeps the lower half calm beside the clouds.
            if animated && star.y < 0.45 && star.id % 6 == 0 {
                opacity *= 0.65 + 0.35 * sin(time * 1.5 + star.twinkleOffset)
            }
            // Stars sitting behind the cloud band fade out so they don't poke through.
            if intensity.cloudOpacity > 0 && y > size.height * 0.34 && y < size.height * 0.84 {
                opacity *= 0.35
            }

            let rect = CGRect(
                x: star.x * size.width,
                y: y,
                width: star.radius,
                height: star.radius
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(star.depth == 0 ? DreamTheme.goldDust.opacity(opacity) : DreamTheme.creamDream.opacity(opacity))
            )
        }
    }

    private func vignette(size: CGSize) -> some View {
        RadialGradient(
            colors: [.clear, DreamTheme.nightIndigo.opacity(intensity == .bedside ? 0.45 : 0.32)],
            center: .center,
            startRadius: size.width * 0.30,
            endRadius: max(size.width, size.height) * 0.85
        )
        .allowsHitTesting(false)
    }
}
