import SwiftUI

// MARK: - Confetti Particle Effect
// MARK: [原理] Canvas + TimelineView 实现 60fps 粒子系统，绕过 SwiftUI 的 View 重建开销
// [原理] SwiftUI 的常规动画（`withAnimation` + `View` 变化）每次状态变化会触发整个 View 树的重计算（`body` 重新执行），
//        对于 50 个粒子来说，50 个独立 View 的状态更新会导致 50 次 `body` 重算，性能极差（掉帧、耗电）。
//        `Canvas` 是 SwiftUI 的"直接渲染"API：你拿到 `GraphicsContext` 后直接调用底层绘制命令（fill、stroke、drawImage），
//        不经过 View 树重建。配合 `TimelineView(.animation)` 以 60fps 驱动，每帧通过 `elapsed` 时间计算粒子位置，直接绘制到屏幕。
//        这是 SwiftUI 中实现高性能粒子/游戏的正确方式。
// [面试] "SwiftUI 能做 60fps 动画吗？怎么做？"
//        答：标准 SwiftUI 动画（`withAnimation` + `State` 变化）受限于 View 重建机制，不适合高帧率、大量元素的动画。
//        60fps 的正确方案：1) `Canvas` + `TimelineView`（如本例的粒子效果）；2) `SpriteKit`（复杂游戏场景）；3) `Metal`（最底层，自定义着色器）。
//        `Canvas` 的优势：完全在 SwiftUI 生态内，无需引入 SpriteKit 框架，代码更简洁。注意点：`Canvas` 的 `onAppear` 中不能安全获取 `size`，
//        因为 `size` 在布局后才确定，所以粒子初始位置需要用 `size.width * 0.3` 这种相对值，在 `context` 闭包中读取 `size`。
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
        // MARK: [原理] TimelineView(.animation) 的显式动画采样：以固定帧率驱动 Canvas 重绘
        // [原理] `TimelineView` 是 SwiftUI 的显式动画调度器。`.animation(minimumInterval: 1.0/60.0)` 表示
        //        以不低于 60fps 的频率调用 `content` 闭包，每次提供一个新的 `TimelineViewDefaultContext`。
        //        `context.date` 是帧的"理论显示时间"（基于 `CADisplayLink` 的 `targetTimestamp`），
        //        不是 `Date()` 的当前时间，这意味着即使主线程阻塞，动画时间仍然是连续的，不会跳帧。
        //        `paused: !isActive` 控制动画的启停：当 `isActive = false` 时，`TimelineView` 停止调度，
        //        Canvas 不再重绘，节省 CPU/GPU。这是显式动画（explicit animation）的核心特征：开发者完全控制
        //        每一帧的更新时机，不依赖 SwiftUI 的隐式状态变化检测。
        // [面试] "TimelineView 和 withAnimation 有什么区别？什么时候用 TimelineView？"
        //        答：`withAnimation` 是隐式动画：你修改 State，SwiftUI 自动检测变化并插入过渡动画。
        //        它适合 UI 状态变化（如按钮点击、页面切换），但帧率由 SwiftUI 内部决定，不适合需要 60fps 的场景。
        //        `TimelineView` 是显式动画：你明确指定刷新间隔（如 1/60 秒），每一帧手动计算并绘制。
        //        适用场景：1) 粒子系统（如本例）；2) 实时图表/波形；3) 游戏循环；4) 视频播放器进度。
        //        关键参数：`minimumInterval` 控制最低刷新率，实际刷新率可能更高（如 ProMotion 屏幕可达 120Hz）；
        //        `paused` 用于节能，页面不可见时应暂停。注意：`TimelineView` 的 `content` 闭包在主线程执行，
        //        如果计算量过大仍会掉帧，复杂场景应结合 `Canvas` 或 offload 到后台线程。
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isActive)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            Canvas { context, size in
                // MARK: [原理] 线性同余发生器（LCG）实现确定性伪随机数，保证 Canvas 可测试和可复现
                // [原理] 如果用 `Double.random(in:)`，每次 Canvas 重绘时粒子位置会随机变化（不可复现），也无法做快照测试。
                //        这里用 LCG（Linear Congruential Generator）伪随机算法：`seed = seed &* 6364136223846793005 &+ 1`。
                //        核心参数 6364136223846793005 是 glibc 的 LCG 乘数，经过统计学验证的"好"参数，周期足够长（2^64），分布均匀。
                //        每次 Canvas 绘制时以固定的 `startTime.hashValue` 为种子，生成的随机数序列完全一致，粒子轨迹是确定性的。
                // [面试] "为什么不用 Swift 的 `random()` 而用自定义 LCG？"
                //        答：两个原因。1) 可复现性：测试时需要相同的粒子轨迹，如果用系统随机数每次测试都会不同；
                //        2) 性能：LCG 是纯整数运算（`&*` 和 `&+`），无系统调用开销，`random()` 底层会访问系统熵池，虽然单次差异不大，
                //        但 60fps × 50 粒子 × 每秒 60 帧 = 每秒 3000 次调用，累积差异明显。注意 `&*` 和 `&+` 是 Swift 的溢出运算符，
                //        保证即使计算溢出也能继续运行（LCG 依赖溢出回绕）。
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

                    // MARK: [原理] 粒子物理模拟：匀速运动 + 重力加速度 + 旋转 + 透明度衰减
                    // [原理] 这里用经典牛顿力学模拟粒子运动：
                    //        - x 方向：匀速运动 `x = startX + vx * t * 30`（30 是速度缩放系数，将随机数映射到屏幕像素）
                    //        - y 方向：竖直上抛运动 `y = startY + vy * t * 30 + 0.5 * 400 * t * t`。
                    //          其中 `vy` 为负（向上抛），`0.5 * 400 * t^2` 是重力加速度项（g ≈ 400 points/s²），
                    //          粒子先上升再下降，形成抛物线轨迹。
                    //        - 旋转：`rotation = rotSpeed * t * 5`，每个粒子以不同角速度旋转，模拟纸片飘落的视觉效果。
                    //        - 透明度衰减：`opacity = max(0, 1.0 - t / (decay * 2.5))`，`decay` 控制每个粒子的寿命，
                    //          在 `t = decay * 2.5` 秒时完全消失。`max(0, ...)` 防止负值。
                    // [面试] "这个粒子效果是怎么做的？物理公式是什么？"
                    //        答：用 Canvas + TimelineView 实现，每帧通过 elapsed 时间计算粒子位置。物理模型是简化版抛体运动：
                    //        `y(t) = y₀ + v₀t + ½gt²`。其中 `v₀` 是初速度（随机向上），`g` 是重力加速度（400 points/s²），
                    //        `t` 是从动画开始经过的时间。关键点：1) 所有参数都是每帧重新计算（状态无持久化），所以内存开销极低；
                    //        2) 用 `guard opacity > 0` 做视锥剔除，屏幕外的粒子不绘制；3) `allowsHitTesting(false)` 让 Canvas 不拦截触摸事件，
                    //        不影响下方按钮交互。如果面试官追问优化：可以将粒子数组缓存到 `@State`，避免每帧重新生成随机数，
                    //        但本例粒子数少（50 个），LCG 性能足够。
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
// MARK: [原理] Overlay + 条件渲染：通过状态控制粒子层的挂载与卸载
// [原理] `overlay` 将 `ConfettiView` 覆盖在目标 View 之上。`isPresented` 为 `true` 时创建 `ConfettiView`，
//        触发 `onAppear` 启动粒子动画；2.5 秒后通过 `DispatchQueue.main.asyncAfter` 自动将 `isPresented` 设为 `false`，
//        `ConfettiView` 被销毁。这种"创建-自动销毁"模式是典型的 ephemeral overlay 设计，避免粒子 View 长期占用内存。
//        `DispatchQueue.main.asyncAfter` 在主线程延迟执行，确保 UI 更新在主线程完成。
// [面试] "SwiftUI 的 overlay 和 ZStack 有什么区别？"
//        答：两者都可以实现层叠布局，但有重要区别。1) `overlay` 是修饰符，被覆盖的 View 决定整体大小，
//        overlay 内容适应其尺寸（类似 CSS 的 `position: absolute; inset: 0`）；`ZStack` 是容器，所有子 View 共同参与布局。
//        2) `overlay` 更适合"装饰性"层（如本例的粒子效果、徽章、加载指示器），语义上表示"附加在...之上"；
//        `ZStack` 更适合"同级"层叠（如背景+内容+前景）。3) 动画方面：`overlay` 的内容可以独立动画，
//        不影响底层 View。注意：`overlay` 默认参与 hit-testing，如果 overlay 覆盖全屏且需要穿透点击，
//        需要给 overlay 内容加 `.allowsHitTesting(false)`（如本例的 `ConfettiView` 已经设置了）。
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
// MARK: [原理] onLongPressGesture + pressing 回调：无延迟的按压状态检测
// [原理] SwiftUI 的 `onLongPressGesture` 通常用于检测"长按"（minimumDuration 达到后触发 `perform`），
//        但通过设置 `minimumDuration: .infinity` 可以禁用 perform 触发，仅使用 `pressing` 回调获取按压状态。
//        `pressing` 在手指按下时立即传 `true`，抬起时传 `false`，没有系统默认的 0.3 秒延迟。
//        `maximumDistance: .infinity` 允许手指在屏幕上滑动时仍然保持按压状态（不触发取消）。
//        这种技巧常用于按钮按下效果：比 `ButtonStyle` 更灵活，因为可以精确控制 scale 和 opacity 的动画参数。
// [面试] "SwiftUI 怎么实现按钮按下去缩小、松开恢复的效果？"
//        答：三种方案。1) 自定义 `ButtonStyle`（最标准，但只能用于 Button）；
//        2) `onLongPressGesture(minimumDuration: .infinity, pressing: { ... })`（如本例，可用于任意 View）；
//        3) `DragGesture(minimumDistance: 0)` 的 `.onChanged` 和 `.onEnded`（最灵活，可获取触摸位置）。
//        本例选择方案 2 的原因是：无需处理 `DragGesture` 的复杂状态机，代码简洁，且 `pressing` 回调直接给出布尔值。
//        注意：`maximumDistance: .infinity` 防止手指轻微滑动就取消按压，提升体验。如果要做更复杂的按压效果
//        （如涟漪扩散），需要用 `DragGesture` 获取触摸坐标。
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

// MARK: - Hover Scale Effect
// MARK: [原理] onHover：跨平台的鼠标悬停检测，底层依赖 NSEvent/UITouch 的映射
// [原理] `onHover` 是 SwiftUI 的跨平台悬停事件 API。在 macOS 上，它直接监听 `NSEvent.mouseMoved` 和 `NSEvent.mouseExited`，
//        通过 `NSTrackingArea` 实现；在 iOS/iPadOS 13.4+ 上，它监听 `UIHoverGestureRecognizer`（指针设备，如妙控鼠标/触控板）。
//        当指针进入/离开 View 的 bounds 时，闭包被调用，`isHovered` 状态切换，触发 `scaleEffect` 动画。
//        注意：`onHover` 在纯触摸设备（无指针）上永远不会触发，所以这种效果属于"渐进增强"，不影响核心体验。
// [面试] "SwiftUI 支持鼠标悬停效果吗？iPad 上能用吗？"
//        答：`onHover` 同时支持 macOS 和 iOS/iPadOS 13.4+（需指针设备，如 Apple Pencil 悬停、妙控鼠标）。
//        实现方式：`View.onHover { isHovered in ... }`，配合 `scaleEffect` 或 `opacity` 做视觉反馈。
//        注意点：1) 它不是 `UIControl` 的 `isHighlighted`，不处理触摸按下；2) 在 iPhone 上无效果，需要配合 `.pressableCard`
//        提供触摸反馈；3) 如果要同时支持悬停和点击，可以组合 `onHover` 和 `onTapGesture`。
//        苹果推荐在 iPad 外接键盘/鼠标时提供悬停反馈，提升桌面级体验。
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
// MARK: [原理] Animatable protocol：SwiftUI 动画的底层插值机制
// [原理] `Animatable` 协议只有一个要求：`animatableData`（`associatedtype AnimatableData: VectorArithmetic`）。
//        当 `withAnimation` 改变了一个 `Animatable` View 的属性时，SwiftUI 不是在动画开始瞬间跳转到目标值，
//        而是：1) 读取 `animatableData` 的当前值；2) 计算目标值与当前值的差值；3) 在动画时长内，每帧通过 easing 函数
//        计算中间值，写回 `animatableData`；4) 触发 `body` 重绘。所以 `AnimatedNumber` 的 `body` 每帧显示的是插值过程中的数字，
//        形成数字滚动的效果。`monospacedDigit()` 确保数字等宽，防止宽度变化导致布局抖动。
// [面试] "SwiftUI 的 Animatable protocol 怎么实现自定义动画？"
//        答：实现三步。1) 让 View 遵循 `Animatable`；2) 实现 `animatableData` 的 getter/setter，映射到需要动画的属性；
//        3) SwiftUI 自动处理插值。比如本例中 `animatableData` 就是 `value`，动画时 SwiftUI 会在 0 到目标值之间平滑插值，
//        `body` 中 `Text(formatter(value))` 每帧显示插值结果。如果要同时动画多个属性，可以用 `AnimatablePair` 组合：
//        `var animatableData: AnimatablePair<CGFloat, CGFloat>`，分别控制 x 和 y 的动画。动画的本质是：SwiftUI 的渲染引擎
//        在运行时反复修改 `animatableData`，然后调用 `body`，利用 View 的声明式特性自动更新界面。
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

// MARK: - Counting Animation Modifier
// MARK: [原理] 动画组合：将 Animatable View 封装为 ViewModifier，实现可复用的数字滚动
// [原理] `CountingAnimationModifier` 是 `AnimatedNumber` 的包装层，负责管理动画的生命周期（onAppear 时启动）。
//        它将"动画什么"（AnimatedNumber 的插值逻辑）和"何时动画"（modifier 的 onAppear 触发）分离，
//        符合单一职责原则。`withAnimation(.easeOut(duration:))` 创建隐式动画，SwiftUI 自动检测
//        `displayedValue` 的变化，通过 `AnimatedNumber.animatableData` 的 setter 注入插值。
//        `easeOut` 让数字快速滚动到接近目标值，然后缓慢逼近，符合"倒计时/计数"的认知习惯。
// [面试] "SwiftUI 中 ViewModifier 和自定义 View 有什么区别？动画场景下怎么选？"
//        答：核心区别在于复用方式。`ViewModifier` 通过 `.modifier(MyModifier())` 或自定义 `.myMethod()` 附加到任意 View，
//        不拥有被修饰 View 的内容；自定义 `View`（`struct MyView: View`）是独立的视图单元。
//        动画场景选择原则：1) 如果动画逻辑需要附加到多种不同类型的 View（如 Text、Image、Rectangle），
//        用 `ViewModifier`（如本例的 `countingAnimation` 可以加到任何 View）；2) 如果动画有独立的视觉表现
//        和内部状态，用自定义 `View`（如 `AnimatedNumber` 只显示数字）。`ViewModifier` 可以组合使用：
//        `Text("123").countingAnimation(to: 100).slideIn(from: .top)`，多个 modifier 按顺序应用。
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
// MARK: [原理] GeometryEffect：直接操作底层 CGAffineTransform，绕过 SwiftUI 的布局系统
// [原理] `GeometryEffect` 是 SwiftUI 中最底层的动画协议，它允许直接修改 View 的仿射变换矩阵（`CGAffineTransform`）。
//        与 `Animatable` 不同：`Animatable` 修改的是 View 的"数据"（通过 `body` 重绘），`GeometryEffect` 修改的是 View 的"变换矩阵"（通过 Core Animation 层）。
//        所以 `GeometryEffect` 更高效（不触发 `body` 重计算），适合高频动画（如连续震动）。
//        `ShakeEffect` 的实现：每帧计算 `x = sin(animatableData * 2π * shakes) * amount`，
//        通过 `sin` 函数产生周期性左右震动。`animatableData` 从 0 到 1，控制 3 个完整周期的震动（`shakes = 3`）。
// [面试] "SwiftUI 的动画有几种层级？各适用于什么场景？"
//        答：三层。1) 隐式动画（`withAnimation` + `State` 变化）：最常用，适合颜色、大小、位置变化；
//        2) `Animatable` 协议：适合自定义插值逻辑（如数字滚动、自定义路径动画），需要 `body` 参与重绘；
//        3) `GeometryEffect`：最底层，直接修改 `CGAffineTransform` 或 `ProjectionTransform`，适合不触发布局的变换（如震动、旋转、缩放）。
//        本例的 `ShakeEffect` 用 `GeometryEffect` 是因为震动只改位置，不需要重新计算 `body` 中的文字、颜色等，性能更好。
//        选择层级原则：如果动画只改变外观属性（不重新计算内容），用 `GeometryEffect`；如果动画改变内容本身（如数字从 0 到 100），
//        用 `Animatable`。
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
// MARK: [原理] 方向性位移动画：从屏幕边缘滑入，建立空间认知
// [原理] 根据 `edge` 参数（.leading/.trailing/.top/.bottom）计算初始偏移量（±30 points），
//        配合 `opacity` 从 0 到 1 的渐变，形成"从屏幕外滑入并淡入"的效果。`delay` 参数支持延迟启动，
//        常用于页面首次加载时让元素按序出现。30 points 的偏移量是 UI 设计经验值：足够让用户感知运动方向，
//        又不会因距离太长而显得拖沓。`.easeOut` 让动画快速启动、缓慢结束，符合"进入视野"的物理直觉。
// [面试] "SwiftUI 怎么做从边缘滑入的动画？"
//        答：使用 `offset` 配合 `opacity` 和 `animation`。核心是根据 `Edge` 计算正确的偏移方向：
//        `.leading` 对应 `x: -30`，`.trailing` 对应 `x: 30`，`.top` 对应 `y: -30`，`.bottom` 对应 `y: 30`。
//        动画启动时机：通常放在 `onAppear` 中设置 `isVisible = true`。注意：`offset` 不改变布局，
//        如果 View 初始状态是隐藏的（`opacity: 0`），它仍然会参与布局计算，只是不可见。
//        这与 `transition(.move(edge:))` 的区别：`transition` 只在 View 出现/消失时播放一次动画，
//        而本例的 modifier 可以在任意状态变化时复用。iOS 15+ 推荐用 `.transition(.asymmetric(insertion: .move(edge:), removal: .opacity))`
//        配合 `withAnimation` 做更现代的入场效果。
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
// MARK: [原理] 呼吸动画：scale + opacity 的组合，制造"脉动"视觉效果
// [原理] 同时改变 `scaleEffect`（1.0 → 1.08）和 `opacity`（1.0 → 0.8），形成放大-变淡-恢复-变浓的循环。
//        人眼对同时变化的大小和透明度非常敏感，这种组合比单一属性变化更醒目。`repeatForever(autoreverses: true)`
//        让动画来回播放，`easeInOut` 使过渡平滑。周期 1.2 秒是经验值：太快会显得焦虑，太慢会被忽略。
//        底层：SwiftUI 将 `scaleEffect` 和 `opacity` 的动画合并为一个 `CAAnimationGroup`，同步执行。
// [面试] "SwiftUI 怎么实现呼吸/脉冲效果？"
//        答：组合 `scaleEffect` 和 `opacity`，配合 `repeatForever(autoreverses: true)`。如：
//        `.scaleEffect(isPulsing ? 1.08 : 1.0).opacity(isPulsing ? 0.8 : 1.0)`。
//        关键参数：1) scale 幅度不宜过大（1.05-1.10），否则显得突兀；2) opacity 不要低于 0.5，否则内容可读性下降；
//        3) 周期 1.0-1.5 秒最合适。如果想做得更精致，可以叠加 `shadow` 动画（放大时 shadow radius 也增大），
//        制造"发光"效果。注意：持续动画会消耗少量 CPU/GPU，页面不可见时（如用户切到别的 App），
//        SwiftUI 会自动暂停动画，无需手动处理。
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
// MARK: [原理] 周期性位移动画：模拟物理弹性的视觉反馈
// [原理] `offset(y:)` 修改 View 的垂直位置，底层通过 `CGAffineTransform(translationX: 0, y: offset)` 实现。
//        `repeatForever(autoreverses: true)` 创建往返动画：0 → -6 → 0 → -6... 形成上下弹跳效果。
//        `.easeInOut` easing 函数让运动有加速和减速，模拟真实物理中"上升减速、下降加速"的规律。
//        这种微动画（micro-animation）用于吸引用户注意力，提示"这里有新内容"或"需要操作"。
// [面试] "SwiftUI 的 offset 和 position 有什么区别？动画时用哪个？"
//        答：`offset(x:y:)` 是在 View 原有位置基础上做相对偏移，不改变布局（其他 View 的位置不受影响）；
//        `position(x:y:)` 是将 View 放置到指定坐标，会脱离正常布局流。动画场景下：
//        1) 如果只是让 View 在原地轻微晃动（如本例的 bounce、shake），用 `offset`；
//        2) 如果要让 View 从一个位置移动到另一个位置（如拖拽、转场），用 `offset` 或 `matchedGeometryEffect`；
//        3) `position` 很少用于动画，因为它破坏布局。性能上两者都是 transform 动画，不触发 layout pass。
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
// MARK: [原理] Stagger（交错）动画：通过 delay 实现视觉层次感
// [原理] 列表中所有元素同时动画会显得单调且拥挤。Stagger 动画让每个元素按索引延迟启动，
//        形成"波浪式"入场效果。公式：`delay = index * 0.06`，第 0 个元素立即开始，第 1 个延迟 0.06 秒，以此类推。
//        底层实现：SwiftUI 的动画系统为每个 View 维护独立的动画状态机，`delay` 只是将动画启动时间向后平移，
//        不占用额外线程。当 `List` 或 `LazyVStack` 的 cell 进入屏幕时触发 `onAppear`，每个 cell 独立计算自己的延迟。
// [面试] "列表动画怎么做？怎么避免 cell 同时出现太突兀？"
//        答：使用 Stagger（交错）动画。核心思路：给每个 cell 的动画加一个与 `index` 成正比的 `delay`。
//        如 `.animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06))`。注意事项：
//        1) `LazyVStack` 中的 cell 只有进入视口才触发 `onAppear`，所以 Stagger 效果只在首次出现时有效；
//        2) 如果列表很长（>50 项），后面的 cell 延迟会很长，用户可能看不到动画，可以将延迟上限 clamp 到 0.5 秒；
//        3) iOS 15+ 可以用 `.transition(.asymmetric(...))` 配合 `.animation(.spring())` 做更现代的入场效果。
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
// MARK: [原理] matchedGeometryEffect 需要跨视图共享同一个 Namespace，必须用全局静态变量
// [原理] `matchedGeometryEffect` 是 SwiftUI 的共享元素转场动画 API。它的工作原理：两个 View 通过同一个 `id` 和 `namespace`
//        建立关联，当其中一个出现、另一个消失时，SwiftUI 会自动在两者之间做平滑的位置/大小插值动画。
//        `Namespace` 是引用类型（class），只有同一个实例才能匹配。如果每个 View 自己创建 `Namespace()`，
//        那它们永远不会匹配（不同实例）。所以必须用全局静态变量 `AppNamespace.namespace`，让所有需要转场动画的 View 共享。
//        这里用 `Namespace().wrappedValue` 是因为 `Namespace` 是 `@Namespace` 属性包装器的底层类型，获取其 `wrappedValue`
//        才能得到 `Namespace.ID`（实际是个 `String`，但框架隐藏了具体类型）。
// [面试] "SwiftUI 的 matchedGeometryEffect 是怎么工作的？有什么坑？"
//        答：`matchedGeometryEffect(id:in:)` 通过 `id + namespace` 做 View 匹配。实现原理：SwiftUI 在渲染时维护一个
//        "几何映射表"，记录每个 namespace 中每个 id 对应的 View frame。当同一 (namespace, id) 出现两个 View 时（一个 entering、一个 exiting），
//        框架自动计算 frame 差值，用弹簧动画过渡。常见坑：1) namespace 必须是同一个实例（本例用全局静态量）；
//        2) 两个 View 不能同时可见（否则框架不知道谁是源谁是目标）；3) 如果 View 嵌套在 `List` 或 `ScrollView` 中，
//        由于 cell 重用机制，匹配可能失效（需要确保两个 View 都在屏幕上或都使用 `.id()` 固定身份）；4) 不支持旋转和形状变化，只支持位置和大小。
enum AppNamespace {
    static let namespace = Namespace().wrappedValue
}

// MARK: - Rotation Effect for Loading
// MARK: [原理] rotationEffect + repeatForever：基于三角函数的连续旋转动画
// [原理] `rotationEffect(.degrees(角度))` 对 View 应用 2D 旋转变换，底层是 `CGAffineTransform(rotationAngle:)`。
//        `.linear(duration: 1).repeatForever(autoreverses: false)` 创建无限循环的线性动画，1 秒转 360 度，即 60 RPM。
//        `autoreverses: false` 确保旋转方向始终一致（顺时针），不会来回摆动。SwiftUI 动画引擎使用 `CADisplayLink`
//        以屏幕刷新率（通常 60/120Hz）驱动，每帧计算当前旋转角度，直接修改 layer 的 `transform` 属性，不触发 View 重建。
// [面试] "SwiftUI 怎么做 loading 动画？"
//        答：常用三种方案。1) `rotationEffect` + `repeatForever`（如本例，适合简单旋转图标）；
//        2) `ProgressView`（系统自带，有 indeterminate 和 determinate 两种模式）；
//        3) 自定义 `Canvas` 绘制（适合复杂加载动画，如渐变圆环）。性能注意：`rotationEffect` 只修改 transform，
//        不触发 `body` 重算，CPU 开销极低。如果面试官问离屏渲染：旋转本身不会触发离屏渲染，但如果 View 有圆角+阴影+透明度组合，
//        可能会被 Core Animation 标记为离屏渲染，可用 Instruments 的 Color Offscreen-Rendered Yellow 检测。
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
// MARK: [原理] rotation3DEffect：基于透视投影的 3D 旋转变换
// [原理] `rotation3DEffect` 是 SwiftUI 对 Core Animation `CATransform3D` 的封装。它创建了一个 3D 透视变换矩阵，
//        绕指定轴（axis）旋转指定角度。默认的 `axis: (0, 1, 0)` 表示绕 Y 轴旋转，形成卡片左右翻转效果。
//        底层通过 `CATransform3DMakeRotation(angle, x, y, z)` 实现，配合 `m34` 透视参数产生近大远小的 3D 视觉效果。
//        `.easeInOut(duration: 0.6)` 让翻转有加速和减速过程，更自然。
// [面试] "SwiftUI 如何实现 3D 翻转效果？"
//        答：使用 `rotation3DEffect(.degrees(角度), axis: (x, y, z))`。关键点：1) `axis` 决定旋转轴，(0,1,0) 是 Y 轴翻转；
//        2) 需要配合 `onTapGesture` 切换状态；3) 如果要做正反面内容切换，需要配合 `ZStack` 和两个 View，
//        通过 `.opacity(isFlipped ? 0 : 1)` 控制显示。注意 `rotation3DEffect` 只旋转一个 View，如果需要双面卡片，
//        必须手动管理两个 View 的可见性。与 `matchedGeometryEffect` 不同，3D 翻转不涉及布局系统，是纯渲染层变换。
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
