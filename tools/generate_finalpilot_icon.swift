import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDirectory = root.appendingPathComponent("FinalPilotApp/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconSpecs: [(String, Int)] = [
    ("Icon-20@2x.png", 40),
    ("Icon-20@3x.png", 60),
    ("Icon-29@2x.png", 58),
    ("Icon-29@3x.png", 87),
    ("Icon-40@2x.png", 80),
    ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120),
    ("Icon-60@3x.png", 180),
    ("Icon-76.png", 76),
    ("Icon-76@2x.png", 152),
    ("Icon-83.5@2x.png", 167),
    ("Icon-1024.png", 1024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawCenteredText(
    _ text: String,
    in rect: CGRect,
    fontSize: CGFloat,
    weight: NSFont.Weight,
    fill: NSColor,
    stroke: NSColor? = nil,
    strokeWidth: CGFloat = 0,
    kern: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    var attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: fill,
        .paragraphStyle: paragraph,
        .kern: kern
    ]

    if let stroke {
        attributes[.strokeColor] = stroke
        attributes[.strokeWidth] = -strokeWidth
    }

    let attributedText = NSAttributedString(string: text, attributes: attributes)
    let bounds = attributedText.boundingRect(
        with: CGSize(width: rect.width, height: rect.height),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    let drawRect = CGRect(
        x: rect.minX,
        y: rect.midY - bounds.height / 2,
        width: rect.width,
        height: bounds.height + fontSize * 0.08
    )
    attributedText.draw(in: drawRect)
}

func drawIcon(size: Int) -> NSBitmapImageRep {
    let side = CGFloat(size)
    guard let representation = NSBitmapImageRep(
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
    ), let graphicsContext = NSGraphicsContext(bitmapImageRep: representation) else {
        fatalError("Could not create bitmap context")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    let context = graphicsContext.cgContext

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            color(0.04, 0.12, 0.18).cgColor,
            color(0.05, 0.40, 0.42).cgColor,
            color(0.14, 0.18, 0.38).cgColor
        ] as CFArray,
        locations: [0.0, 0.52, 1.0]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: side),
        end: CGPoint(x: side, y: 0),
        options: []
    )

    context.saveGState()
    context.translateBy(x: 0, y: side)
    context.scaleBy(x: 1, y: -1)

    context.setLineWidth(max(1, side * 0.006))
    context.setStrokeColor(color(1, 1, 1, 0.08).cgColor)
    for offset in stride(from: side * 0.18, through: side * 0.82, by: side * 0.16) {
        context.move(to: CGPoint(x: side * 0.14, y: offset))
        context.addLine(to: CGPoint(x: side * 0.86, y: offset + side * 0.06))
        context.strokePath()
    }

    let glow = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            color(0.95, 0.60, 0.23, 0.36).cgColor,
            color(0.95, 0.60, 0.23, 0.00).cgColor
        ] as CFArray,
        locations: [0.0, 1.0]
    )!
    context.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: side * 0.70, y: side * 0.22),
        startRadius: side * 0.02,
        endCenter: CGPoint(x: side * 0.70, y: side * 0.22),
        endRadius: side * 0.58,
        options: []
    )

    let badge = CGRect(x: side * 0.115, y: side * 0.185, width: side * 0.77, height: side * 0.63)
    context.setShadow(offset: CGSize(width: 0, height: side * 0.045), blur: side * 0.07, color: color(0, 0, 0, 0.27).cgColor)
    context.setFillColor(color(0.02, 0.08, 0.12, 0.58).cgColor)
    context.addPath(roundedRect(badge, radius: side * 0.12))
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0, color: nil)

    context.setStrokeColor(color(1, 1, 1, 0.20).cgColor)
    context.setLineWidth(side * 0.012)
    context.addPath(roundedRect(badge.insetBy(dx: side * 0.018, dy: side * 0.018), radius: side * 0.10))
    context.strokePath()

    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineWidth(side * 0.045)
    context.setStrokeColor(color(0.96, 0.64, 0.25).cgColor)
    context.move(to: CGPoint(x: side * 0.22, y: side * 0.67))
    context.addCurve(
        to: CGPoint(x: side * 0.80, y: side * 0.33),
        control1: CGPoint(x: side * 0.34, y: side * 0.38),
        control2: CGPoint(x: side * 0.58, y: side * 0.62)
    )
    context.strokePath()

    let nodes: [(CGFloat, CGFloat, CGFloat)] = [
        (0.22, 0.67, 0.036),
        (0.50, 0.49, 0.030),
        (0.80, 0.33, 0.036)
    ]
    for (x, y, radius) in nodes {
        let r = side * radius
        let rect = CGRect(x: side * x - r, y: side * y - r, width: r * 2, height: r * 2)
        context.setFillColor(color(1, 1, 1).cgColor)
        context.fillEllipse(in: rect.insetBy(dx: -side * 0.006, dy: -side * 0.006))
        context.setFillColor(color(0.94, 0.56, 0.23).cgColor)
        context.fillEllipse(in: rect)
    }

    let leftPage = CGMutablePath()
    leftPage.move(to: CGPoint(x: side * 0.24, y: side * 0.71))
    leftPage.addCurve(
        to: CGPoint(x: side * 0.48, y: side * 0.74),
        control1: CGPoint(x: side * 0.32, y: side * 0.67),
        control2: CGPoint(x: side * 0.41, y: side * 0.68)
    )
    leftPage.addLine(to: CGPoint(x: side * 0.48, y: side * 0.84))
    leftPage.addCurve(
        to: CGPoint(x: side * 0.24, y: side * 0.80),
        control1: CGPoint(x: side * 0.40, y: side * 0.79),
        control2: CGPoint(x: side * 0.31, y: side * 0.78)
    )
    leftPage.closeSubpath()

    let rightPage = CGMutablePath()
    rightPage.move(to: CGPoint(x: side * 0.52, y: side * 0.74))
    rightPage.addCurve(
        to: CGPoint(x: side * 0.76, y: side * 0.71),
        control1: CGPoint(x: side * 0.59, y: side * 0.68),
        control2: CGPoint(x: side * 0.68, y: side * 0.67)
    )
    rightPage.addLine(to: CGPoint(x: side * 0.76, y: side * 0.80))
    rightPage.addCurve(
        to: CGPoint(x: side * 0.52, y: side * 0.84),
        control1: CGPoint(x: side * 0.69, y: side * 0.78),
        control2: CGPoint(x: side * 0.60, y: side * 0.79)
    )
    rightPage.closeSubpath()

    context.setShadow(offset: CGSize(width: 0, height: side * 0.018), blur: side * 0.030, color: color(0, 0, 0, 0.20).cgColor)
    context.setFillColor(color(1, 1, 1).cgColor)
    context.addPath(leftPage)
    context.fillPath()
    context.addPath(rightPage)
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0, color: nil)

    context.setStrokeColor(color(0.08, 0.32, 0.36, 0.24).cgColor)
    context.setLineWidth(side * 0.012)
    context.move(to: CGPoint(x: side * 0.50, y: side * 0.72))
    context.addLine(to: CGPoint(x: side * 0.50, y: side * 0.84))
    context.strokePath()

    for y in [0.765, 0.795] as [CGFloat] {
        context.move(to: CGPoint(x: side * 0.29, y: side * y))
        context.addCurve(
            to: CGPoint(x: side * 0.44, y: side * (y + 0.015)),
            control1: CGPoint(x: side * 0.34, y: side * (y - 0.012)),
            control2: CGPoint(x: side * 0.39, y: side * y)
        )
        context.move(to: CGPoint(x: side * 0.56, y: side * (y + 0.015)))
        context.addCurve(
            to: CGPoint(x: side * 0.71, y: side * y),
            control1: CGPoint(x: side * 0.61, y: side * y),
            control2: CGPoint(x: side * 0.66, y: side * (y - 0.012))
        )
    }
    context.strokePath()

    context.restoreGState()

    drawCenteredText(
        "XYX",
        in: CGRect(x: side * 0.11, y: side * 0.315, width: side * 0.78, height: side * 0.28),
        fontSize: side * 0.205,
        weight: .black,
        fill: color(0.98, 1.00, 0.96),
        stroke: color(0.02, 0.10, 0.12, 0.42),
        strokeWidth: side * 0.010,
        kern: side * 0.004
    )

    drawCenteredText(
        "学呀学",
        in: CGRect(x: side * 0.22, y: side * 0.575, width: side * 0.56, height: side * 0.08),
        fontSize: side * 0.058,
        weight: .semibold,
        fill: color(0.96, 0.64, 0.25),
        kern: side * 0.004
    )

    NSGraphicsContext.restoreGraphicsState()
    return representation
}

func writePNG(_ representation: NSBitmapImageRep, to url: URL) throws {
    guard let data = representation.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }
    try data.write(to: url)
}

for (fileName, size) in iconSpecs {
    let representation = drawIcon(size: size)
    try writePNG(representation, to: outputDirectory.appendingPathComponent(fileName))
}

print("Generated \(iconSpecs.count) FinalPilot app icon files.")
