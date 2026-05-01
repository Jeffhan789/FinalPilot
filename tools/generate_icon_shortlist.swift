import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDirectory = root.appendingPathComponent("design/icon_shortlist")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

struct RGBA {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat

    init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    var ns: NSColor {
        NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
    }

    var cg: CGColor {
        ns.cgColor
    }
}

struct ShortlistIcon {
    let number: Int
    let key: String
    let title: String
    let draw: (CGContext, CGFloat) -> Void
}

let navy = RGBA(0.025, 0.095, 0.120)
let teal = RGBA(0.025, 0.390, 0.380)
let blue = RGBA(0.070, 0.180, 0.360)
let amber = RGBA(0.970, 0.620, 0.210)
let cream = RGBA(0.970, 0.985, 0.920)
let ink = RGBA(0.035, 0.110, 0.125)

func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func gradient(_ context: CGContext, side: CGFloat, colors: [RGBA], locations: [CGFloat]? = nil) {
    let g = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cg) as CFArray,
        locations: locations
    )!
    context.drawLinearGradient(g, start: CGPoint(x: 0, y: side), end: CGPoint(x: side, y: 0), options: [])
}

func glow(_ context: CGContext, side: CGFloat, x: CGFloat, y: CGFloat, radius: CGFloat, color: RGBA) {
    let g = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color.cg,
            RGBA(color.r, color.g, color.b, 0).cg
        ] as CFArray,
        locations: [0, 1]
    )!
    let center = CGPoint(x: side * x, y: side * y)
    context.drawRadialGradient(g, startCenter: center, startRadius: 0, endCenter: center, endRadius: side * radius, options: [])
}

func text(
    _ string: String,
    in rect: CGRect,
    size: CGFloat,
    color: RGBA,
    fontName: String,
    kern: CGFloat = 0,
    stroke: RGBA? = nil,
    strokeWidth: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let font = NSFont(name: fontName, size: size) ?? NSFont.systemFont(ofSize: size, weight: .black)
    var attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color.ns,
        .paragraphStyle: paragraph,
        .kern: kern
    ]
    if let stroke {
        attributes[.strokeColor] = stroke.ns
        attributes[.strokeWidth] = -strokeWidth
    }
    let attributed = NSAttributedString(string: string, attributes: attributes)
    let bounds = attributed.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading])
    let drawRect = CGRect(
        x: rect.minX,
        y: rect.midY - bounds.height * 0.50,
        width: rect.width,
        height: bounds.height + size * 0.14
    )
    attributed.draw(in: drawRect)
}

func line(_ context: CGContext, side: CGFloat, from a: CGPoint, to b: CGPoint, color: RGBA, width: CGFloat) {
    context.setStrokeColor(color.cg)
    context.setLineWidth(side * width)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: side * a.x, y: side * a.y))
    context.addLine(to: CGPoint(x: side * b.x, y: side * b.y))
    context.strokePath()
}

func node(_ context: CGContext, side: CGFloat, x: CGFloat, y: CGFloat, r: CGFloat, fill: RGBA = amber) {
    let rect = CGRect(x: side * (x - r), y: side * (y - r), width: side * r * 2, height: side * r * 2)
    context.setFillColor(cream.cg)
    context.fillEllipse(in: rect.insetBy(dx: -side * 0.007, dy: -side * 0.007))
    context.setFillColor(fill.cg)
    context.fillEllipse(in: rect)
}

func book(_ context: CGContext, side: CGFloat, y: CGFloat, scale: CGFloat) {
    let center = side * 0.5
    let bottom = side * y
    let w = side * 0.23 * scale
    let h = side * 0.13 * scale
    let gap = side * 0.014
    let left = CGMutablePath()
    left.move(to: CGPoint(x: center - gap, y: bottom))
    left.addCurve(to: CGPoint(x: center - w, y: bottom + h * 0.12), control1: CGPoint(x: center - w * 0.30, y: bottom + h * 0.10), control2: CGPoint(x: center - w * 0.66, y: bottom + h * 0.13))
    left.addLine(to: CGPoint(x: center - w, y: bottom + h))
    left.addCurve(to: CGPoint(x: center - gap, y: bottom + h * 0.75), control1: CGPoint(x: center - w * 0.64, y: bottom + h * 1.06), control2: CGPoint(x: center - w * 0.22, y: bottom + h))
    left.closeSubpath()
    let right = CGMutablePath()
    right.move(to: CGPoint(x: center + gap, y: bottom))
    right.addCurve(to: CGPoint(x: center + w, y: bottom + h * 0.12), control1: CGPoint(x: center + w * 0.30, y: bottom + h * 0.10), control2: CGPoint(x: center + w * 0.66, y: bottom + h * 0.13))
    right.addLine(to: CGPoint(x: center + w, y: bottom + h))
    right.addCurve(to: CGPoint(x: center + gap, y: bottom + h * 0.75), control1: CGPoint(x: center + w * 0.64, y: bottom + h * 1.06), control2: CGPoint(x: center + w * 0.22, y: bottom + h))
    right.closeSubpath()
    context.setFillColor(cream.cg)
    context.addPath(left)
    context.fillPath()
    context.addPath(right)
    context.fillPath()
}

func render(size: Int, icon: ShortlistIcon) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ), let graphics = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Could not create bitmap")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    icon.draw(graphics.cgContext, CGFloat(size))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func save(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }
    try data.write(to: url)
}

func fileName(_ icon: ShortlistIcon) -> String {
    "shortlist_\(String(format: "%02d", icon.number))_\(icon.key).png"
}

let icons: [ShortlistIcon] = [
    ShortlistIcon(number: 1, key: "simple_xue", title: "01 简体极简") { context, side in
        gradient(context, side: side, colors: [navy, teal, blue])
        glow(context, side: side, x: 0.74, y: 0.72, radius: 0.52, color: RGBA(1.0, 0.65, 0.20, 0.35))
        let circle = CGRect(x: side * 0.16, y: side * 0.17, width: side * 0.68, height: side * 0.68)
        context.setFillColor(RGBA(0.01, 0.06, 0.08, 0.54).cg)
        context.fillEllipse(in: circle)
        context.setStrokeColor(amber.cg)
        context.setLineWidth(side * 0.028)
        context.strokeEllipse(in: circle.insetBy(dx: side * 0.025, dy: side * 0.025))
        text("学", in: CGRect(x: side * 0.15, y: side * 0.31, width: side * 0.70, height: side * 0.40), size: side * 0.37, color: cream, fontName: "PingFangSC-Semibold")
        text("XYX", in: CGRect(x: side * 0.31, y: side * 0.23, width: side * 0.38, height: side * 0.08), size: side * 0.064, color: amber, fontName: "AvenirNext-Heavy", kern: side * 0.010)
    },
    ShortlistIcon(number: 2, key: "traditional_xue", title: "02 繁体极简") { context, side in
        gradient(context, side: side, colors: [RGBA(0.91, 0.94, 0.88), RGBA(0.75, 0.91, 0.88), RGBA(0.13, 0.38, 0.40)])
        let card = CGRect(x: side * 0.15, y: side * 0.16, width: side * 0.70, height: side * 0.70)
        context.setFillColor(ink.cg)
        context.addPath(roundedRect(card, radius: side * 0.17))
        context.fillPath()
        context.setStrokeColor(amber.cg)
        context.setLineWidth(side * 0.022)
        context.addPath(roundedRect(card.insetBy(dx: side * 0.030, dy: side * 0.030), radius: side * 0.13))
        context.strokePath()
        text("學", in: CGRect(x: side * 0.15, y: side * 0.31, width: side * 0.70, height: side * 0.41), size: side * 0.34, color: cream, fontName: "PingFangTC-Semibold")
        text("XYX", in: CGRect(x: side * 0.30, y: side * 0.23, width: side * 0.40, height: side * 0.08), size: side * 0.064, color: amber, fontName: "AvenirNext-Heavy", kern: side * 0.011)
    },
    ShortlistIcon(number: 3, key: "x_xue_x", title: "03 X学X") { context, side in
        gradient(context, side: side, colors: [RGBA(0.02, 0.12, 0.14), RGBA(0.04, 0.41, 0.36), RGBA(0.92, 0.57, 0.18)])
        let panel = CGRect(x: side * 0.10, y: side * 0.26, width: side * 0.80, height: side * 0.48)
        context.setFillColor(RGBA(0.01, 0.06, 0.08, 0.56).cg)
        context.addPath(roundedRect(panel, radius: side * 0.13))
        context.fillPath()
        text("X", in: CGRect(x: side * 0.11, y: side * 0.37, width: side * 0.27, height: side * 0.28), size: side * 0.25, color: cream, fontName: "AvenirNext-Heavy")
        text("学", in: CGRect(x: side * 0.32, y: side * 0.32, width: side * 0.36, height: side * 0.37), size: side * 0.29, color: amber, fontName: "PingFangSC-Semibold")
        text("X", in: CGRect(x: side * 0.62, y: side * 0.37, width: side * 0.27, height: side * 0.28), size: side * 0.25, color: cream, fontName: "AvenirNext-Heavy")
    },
    ShortlistIcon(number: 4, key: "x_traditional_x", title: "04 X學X") { context, side in
        gradient(context, side: side, colors: [RGBA(0.06, 0.09, 0.20), RGBA(0.12, 0.30, 0.48), RGBA(0.03, 0.18, 0.18)])
        glow(context, side: side, x: 0.33, y: 0.77, radius: 0.48, color: RGBA(0.40, 0.86, 0.82, 0.32))
        line(context, side: side, from: CGPoint(x: 0.21, y: 0.28), to: CGPoint(x: 0.50, y: 0.65), color: amber, width: 0.035)
        line(context, side: side, from: CGPoint(x: 0.50, y: 0.65), to: CGPoint(x: 0.79, y: 0.40), color: amber, width: 0.035)
        node(context, side: side, x: 0.21, y: 0.28, r: 0.030)
        node(context, side: side, x: 0.50, y: 0.65, r: 0.030)
        node(context, side: side, x: 0.79, y: 0.40, r: 0.030)
        text("X學X", in: CGRect(x: side * 0.09, y: side * 0.32, width: side * 0.82, height: side * 0.34), size: side * 0.23, color: cream, fontName: "PingFangTC-Semibold", kern: -side * 0.004, stroke: RGBA(0, 0, 0, 0.25), strokeWidth: side * 0.006)
    },
    ShortlistIcon(number: 5, key: "seal_xue", title: "05 学印章") { context, side in
        gradient(context, side: side, colors: [RGBA(0.04, 0.12, 0.14), RGBA(0.06, 0.44, 0.39), RGBA(0.84, 0.42, 0.18)])
        let seal = CGRect(x: side * 0.18, y: side * 0.18, width: side * 0.64, height: side * 0.64)
        context.setFillColor(amber.cg)
        context.addPath(roundedRect(seal, radius: side * 0.16))
        context.fillPath()
        context.setStrokeColor(cream.cg)
        context.setLineWidth(side * 0.018)
        context.addPath(roundedRect(seal.insetBy(dx: side * 0.040, dy: side * 0.040), radius: side * 0.115))
        context.strokePath()
        text("学", in: CGRect(x: side * 0.18, y: side * 0.32, width: side * 0.64, height: side * 0.38), size: side * 0.34, color: cream, fontName: "PingFangSC-Semibold", stroke: RGBA(0.18, 0.08, 0.02, 0.25), strokeWidth: side * 0.006)
        text("XYX", in: CGRect(x: side * 0.31, y: side * 0.24, width: side * 0.38, height: side * 0.08), size: side * 0.060, color: RGBA(0.15, 0.08, 0.03, 0.70), fontName: "AvenirNext-Heavy", kern: side * 0.010)
    },
    ShortlistIcon(number: 6, key: "book_learning", title: "06 学书页") { context, side in
        gradient(context, side: side, colors: [navy, teal, blue])
        glow(context, side: side, x: 0.72, y: 0.73, radius: 0.42, color: RGBA(1, 0.66, 0.22, 0.32))
        context.setStrokeColor(RGBA(1, 1, 1, 0.10).cg)
        context.setLineWidth(side * 0.007)
        for y in [0.30, 0.45, 0.60, 0.75] as [CGFloat] {
            context.move(to: CGPoint(x: side * 0.16, y: side * y))
            context.addLine(to: CGPoint(x: side * 0.84, y: side * (y + 0.045)))
        }
        context.strokePath()
        book(context, side: side, y: 0.19, scale: 1.14)
        text("学", in: CGRect(x: side * 0.19, y: side * 0.44, width: side * 0.62, height: side * 0.31), size: side * 0.30, color: cream, fontName: "PingFangSC-Semibold", stroke: RGBA(0, 0, 0, 0.32), strokeWidth: side * 0.007)
        text("XYX", in: CGRect(x: side * 0.30, y: side * 0.36, width: side * 0.40, height: side * 0.08), size: side * 0.060, color: amber, fontName: "AvenirNext-Heavy", kern: side * 0.011)
    },
    ShortlistIcon(number: 7, key: "cloud_xue", title: "07 云端学") { context, side in
        gradient(context, side: side, colors: [RGBA(0.03, 0.10, 0.18), RGBA(0.07, 0.28, 0.44), RGBA(0.38, 0.64, 0.70)])
        for pair in [(0.22, 0.70, 0.45, 0.78), (0.45, 0.78, 0.70, 0.68), (0.26, 0.34, 0.51, 0.26), (0.51, 0.26, 0.76, 0.36)] {
            line(context, side: side, from: CGPoint(x: pair.0, y: pair.1), to: CGPoint(x: pair.2, y: pair.3), color: RGBA(1, 1, 1, 0.18), width: 0.009)
        }
        for p in [(0.22, 0.70), (0.45, 0.78), (0.70, 0.68), (0.26, 0.34), (0.51, 0.26), (0.76, 0.36)] {
            node(context, side: side, x: p.0, y: p.1, r: 0.020, fill: amber)
        }
        let cloud = CGMutablePath()
        cloud.move(to: CGPoint(x: side * 0.22, y: side * 0.39))
        cloud.addCurve(to: CGPoint(x: side * 0.36, y: side * 0.54), control1: CGPoint(x: side * 0.22, y: side * 0.49), control2: CGPoint(x: side * 0.30, y: side * 0.54))
        cloud.addCurve(to: CGPoint(x: side * 0.55, y: side * 0.59), control1: CGPoint(x: side * 0.41, y: side * 0.69), control2: CGPoint(x: side * 0.54, y: side * 0.68))
        cloud.addCurve(to: CGPoint(x: side * 0.78, y: side * 0.39), control1: CGPoint(x: side * 0.70, y: side * 0.62), control2: CGPoint(x: side * 0.83, y: side * 0.52))
        cloud.closeSubpath()
        context.setFillColor(cream.cg)
        context.addPath(cloud)
        context.fillPath()
        text("学", in: CGRect(x: side * 0.31, y: side * 0.40, width: side * 0.38, height: side * 0.30), size: side * 0.24, color: ink, fontName: "PingFangSC-Semibold")
        text("XYX", in: CGRect(x: side * 0.31, y: side * 0.28, width: side * 0.38, height: side * 0.08), size: side * 0.060, color: amber, fontName: "AvenirNext-Heavy", kern: side * 0.011)
    },
    ShortlistIcon(number: 8, key: "planner_y", title: "08 XYX调度") { context, side in
        gradient(context, side: side, colors: [RGBA(0.03, 0.11, 0.15), RGBA(0.05, 0.36, 0.36), RGBA(0.76, 0.25, 0.18)])
        line(context, side: side, from: CGPoint(x: 0.18, y: 0.25), to: CGPoint(x: 0.50, y: 0.62), color: amber, width: 0.038)
        line(context, side: side, from: CGPoint(x: 0.50, y: 0.62), to: CGPoint(x: 0.82, y: 0.25), color: amber, width: 0.038)
        line(context, side: side, from: CGPoint(x: 0.50, y: 0.62), to: CGPoint(x: 0.50, y: 0.78), color: amber, width: 0.038)
        node(context, side: side, x: 0.18, y: 0.25, r: 0.028)
        node(context, side: side, x: 0.50, y: 0.62, r: 0.032)
        node(context, side: side, x: 0.82, y: 0.25, r: 0.028)
        node(context, side: side, x: 0.50, y: 0.78, r: 0.026)
        text("XYX", in: CGRect(x: side * 0.16, y: side * 0.38, width: side * 0.68, height: side * 0.24), size: side * 0.17, color: cream, fontName: "AvenirNext-Heavy", kern: side * 0.012, stroke: RGBA(0, 0, 0, 0.25), strokeWidth: side * 0.006)
        text("学", in: CGRect(x: side * 0.38, y: side * 0.22, width: side * 0.24, height: side * 0.13), size: side * 0.10, color: cream, fontName: "PingFangSC-Semibold")
    }
]

for icon in icons {
    try save(render(size: 1024, icon: icon), to: outputDirectory.appendingPathComponent(fileName(icon)))
}

let columns = 4
let thumb = 240
let label = 52
let padding = 32
let rows = Int(ceil(Double(icons.count) / Double(columns)))
let width = columns * thumb + (columns + 1) * padding
let height = rows * (thumb + label) + (rows + 1) * padding

guard let sheet = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 32
), let graphics = NSGraphicsContext(bitmapImageRep: sheet) else {
    fatalError("Could not create sheet")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
let ctx = graphics.cgContext
ctx.setFillColor(RGBA(0.92, 0.95, 0.94).cg)
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

for (index, icon) in icons.enumerated() {
    let column = index % columns
    let row = rows - 1 - index / columns
    let x = padding + column * (thumb + padding)
    let y = padding + row * (thumb + label + padding)
    if let cgImage = render(size: thumb, icon: icon).cgImage {
        ctx.setShadow(offset: CGSize(width: 0, height: 8), blur: 14, color: RGBA(0, 0, 0, 0.16).cg)
        ctx.draw(cgImage, in: CGRect(x: x, y: y + label, width: thumb, height: thumb))
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
    }
    text(icon.title, in: CGRect(x: x, y: y + 8, width: thumb, height: 34), size: 24, color: ink, fontName: "PingFangSC-Semibold")
}

NSGraphicsContext.restoreGraphicsState()
try save(sheet, to: outputDirectory.appendingPathComponent("FinalPilot_XYX_shortlist.png"))

let readme = """
# FinalPilot XYX 图标 Shortlist

这些图标是第二轮候选稿，重点是减少小字、放大主体、强化 `学 / 學 / XYX` 融合。

| 编号 | 方向 | 文件 |
| --- | --- | --- |
\(icons.map { "| \($0.number) | \($0.title) | `\(fileName($0))` |" }.joined(separator: "\n"))

预览总图：`FinalPilot_XYX_shortlist.png`
"""

try readme.write(to: outputDirectory.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
print("Generated \(icons.count) shortlist icons in \(outputDirectory.path)")
