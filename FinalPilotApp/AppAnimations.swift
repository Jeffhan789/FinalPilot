import SwiftUI

// MARK: - Confetti Particle Effect
struct ConfettiView: View {
    let colors: [Color]
    let particleCount: Int
    @State private var startTime = Date()
    @State private var isActive = true

    init(colors: [Color] = [AppTheme.primary, AppTheme.orange, AppTheme.green, AppTheme.warning],
         particleCount: Int = 50) {
        self.colors = colors
        self.particleCount = particleCount
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isActive)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            Canvas { context, size in
                // Deterministic particles based on fixed seed
                var seed = startTime.hashValue
                func nextRandom() -> Double {
                    seed = seed &* 6364136223846793005 &+ 1
                    return Double(UInt64(bitPattern: Int64(seed))) / Double(UInt64.max)
                }
                func randCGFloat(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
                    min + CGFloat(nextRandom()) * (max - min)
                }

                for _ in 0..<particleCount {
                    let t = CGFloat(elapsed)
                    let startX = randCGFloat(size.width * 0.3, size.width * 0.7)
                    let startY = randCGFloat(size.height * 0.3, size.height * 0.5)
                    let vx = randCGFloat(-3, 3)
                    let vy = randCGFloat(-10, -3)
                    let w = randCGFloat(6, 12)
                    let h = randCGFloat(4, 8)
                    let colorIndex = Int(randCGFloat(0, CGFloat(colors.count)))
                    let color = colors[colorIndex % colors.count]
                    let rotSpeed = randCGFloat(-0.3, 0.3)
                    let decay = randCGFloat(0.4, 0.9)

                    let x = startX + vx * t * 30
                    let y = startY + vy * t * 30 + 0.5 * 400 * t * t
                    let rotation = rotSpeed * t * 5
                    let opacity = max(0, 1.0 - Double(t) / Double(decay * 2.5))

                    guard opacity > 0, y < size.height + 50, y > -50, x > -50, x < size.width + 50 else { continue }

                    var transform = CGAffineTransform.identity
                        .translatedBy(x: x, y: y)
                        .rotated(by: rotation)

                    let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)

                    context.fill(
                        Path(rect.applying(transform)),
                        with: .color(color.opacity(opacity))
                    )
                }
            }
        }
        .onAppear {
            startTime = Date()
            isActive = true
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Confetti Trigger Overlay
struct ConfettiOverlay: ViewModifier {
    @Binding var isPresented: Bool
    let colors: [Color]

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        ConfettiView(colors: colors)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    isPresented = false
                                }
                            }
                    }
                }
            )
    }
}

extension View {
    func confettiOverlay(isPresented: Binding<Bool>, colors: [Color] = [AppTheme.primary, AppTheme.orange, AppTheme.green]) -> some View {
        modifier(ConfettiOverlay(isPresented: isPresented, colors: colors))
    }
}

// MARK: - Pressable Card Effect
struct PressableCardStyle: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.97
    var opacity: Double = 0.9

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .opacity(isPressed ? opacity : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .onLongPressGesture(
                minimumDuration: .infinity,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: {}
            )
    }
}

struct HoverScaleEffect: ViewModifier {
    @State private var isHovered = false
    var scale: CGFloat = 1.02

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hover in
                isHovered = hover
            }
    }
}

extension View {
    func pressableCard(scale: CGFloat = 0.97, opacity: Double = 0.9) -> some View {
        modifier(PressableCardStyle(scale: scale, opacity: opacity))
    }

    func hoverScale(scale: CGFloat = 1.02) -> some View {
        modifier(HoverScaleEffect(scale: scale))
    }
}

// MARK: - Animated Number
struct AnimatedNumber: View, Animatable {
    var value: Double
    var formatter: (Double) -> String = { String(format: "%.0f", $0) }

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(formatter(value))
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(AppTheme.ink)
            .monospacedDigit()
    }
}

struct CountingAnimationModifier: ViewModifier {
    @State private var displayedValue: Double = 0
    let targetValue: Double
    let duration: Double

    func body(content: Content) -> some View {
        AnimatedNumber(value: displayedValue)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayedValue = targetValue
                }
            }
    }
}

extension View {
    func countingAnimation(from: Double = 0, to target: Double, duration: Double = 1.0) -> some View {
        modifier(CountingAnimationModifier(targetValue: target, duration: duration))
    }
}

// MARK: - Shake Effect (Error Feedback)
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    var multiplier: CGFloat {
        2 * .pi * shakes
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = sin(animatableData * multiplier) * amount
        return ProjectionTransform(CGAffineTransform(translationX: x, y: 0))
    }
}

extension View {
    func shake(amount: CGFloat = 8, shakes: CGFloat = 3, trigger: Bool) -> some View {
        self.modifier(ShakeEffect(amount: amount, shakes: shakes, animatableData: trigger ? 1 : 0))
    }
}

// MARK: - Slide In Animation
struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? (isVisible ? 0 : -30) : (edge == .trailing ? (isVisible ? 0 : 30) : 0),
                y: edge == .top ? (isVisible ? 0 : -30) : (edge == .bottom ? (isVisible ? 0 : 30) : 0)
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInModifier(edge: edge, delay: delay))
    }
}

// MARK: - Pulse Animation (Attention)
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.08 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseModifier())
    }
}

// MARK: - Bounce Animation
struct BounceModifier: ViewModifier {
    @State private var isBouncing = false

    func body(content: Content) -> some View {
        content
            .offset(y: isBouncing ? -6 : 0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isBouncing)
            .onAppear {
                isBouncing = true
            }
    }
}

extension View {
    func bounceAnimation() -> some View {
        modifier(BounceModifier())
    }
}

// MARK: - Fade In Stagger (for Lists)
struct FadeInStaggerModifier: ViewModifier {
    let index: Int
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 12)
            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func fadeInStagger(index: Int) -> some View {
        modifier(FadeInStaggerModifier(index: index))
    }
}

// MARK: - Matched Geometry Namespace
enum AppNamespace {
    static let namespace = Namespace().wrappedValue
}

// MARK: - Rotation Effect for Loading
struct RotationModifier: ViewModifier {
    @State private var isRotating = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
            .onAppear {
                isRotating = true
            }
    }
}

extension View {
    func continuousRotation() -> some View {
        modifier(RotationModifier())
    }
}

// MARK: - Card Flip Animation
struct FlipModifier: ViewModifier {
    @State private var isFlipped = false
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: axis
            )
            .animation(.easeInOut(duration: 0.6), value: isFlipped)
            .onTapGesture {
                isFlipped.toggle()
            }
    }
}

extension View {
    func flipOnTap(axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0)) -> some View {
        modifier(FlipModifier(axis: axis))
    }
}
