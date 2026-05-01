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
            color(0.06, 0.16, 0.22).cgColor,
            color(0.10, 0.42, 0.47).cgColor,
            color(0.08, 0.22, 0.42).cgColor
        ] as CFArray,
        locations: [0.0, 0.55, 1.0]
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

    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineWidth(side * 0.055)
    context.setStrokeColor(color(0.94, 0.56, 0.23).cgColor)
    context.move(to: CGPoint(x: side * 0.20, y: side * 0.70))
    context.addCurve(
        to: CGPoint(x: side * 0.82, y: side * 0.30),
        control1: CGPoint(x: side * 0.34, y: side * 0.40),
        control2: CGPoint(x: side * 0.58, y: side * 0.66)
    )
    context.strokePath()

    let nodes: [(CGFloat, CGFloat, CGFloat)] = [
        (0.20, 0.70, 0.040),
        (0.52, 0.50, 0.034),
        (0.82, 0.30, 0.040)
    ]
    for (x, y, radius) in nodes {
        let r = side * radius
        let rect = CGRect(x: side * x - r, y: side * y - r, width: r * 2, height: r * 2)
        context.setFillColor(color(1, 1, 1).cgColor)
        context.fillEllipse(in: rect.insetBy(dx: -side * 0.006, dy: -side * 0.006))
        context.setFillColor(color(0.94, 0.56, 0.23).cgColor)
        context.fillEllipse(in: rect)
    }

    let plane = CGMutablePath()
    plane.move(to: CGPoint(x: side * 0.27, y: side * 0.30))
    plane.addLine(to: CGPoint(x: side * 0.76, y: side * 0.45))
    plane.addLine(to: CGPoint(x: side * 0.38, y: side * 0.56))
    plane.addLine(to: CGPoint(x: side * 0.45, y: side * 0.42))
    plane.closeSubpath()

    context.setShadow(offset: CGSize(width: 0, height: side * 0.025), blur: side * 0.035, color: color(0, 0, 0, 0.22).cgColor)
    context.setFillColor(color(1, 1, 1).cgColor)
    context.addPath(plane)
    context.fillPath()
    context.setShadow(offset: .zero, blur: 0, color: nil)

    let fold = CGMutablePath()
    fold.move(to: CGPoint(x: side * 0.45, y: side * 0.42))
    fold.addLine(to: CGPoint(x: side * 0.76, y: side * 0.45))
    fold.addLine(to: CGPoint(x: side * 0.38, y: side * 0.56))
    context.addPath(fold)
    context.setStrokeColor(color(0.10, 0.42, 0.47, 0.28).cgColor)
    context.setLineWidth(side * 0.018)
    context.strokePath()

    let bolt = CGMutablePath()
    bolt.move(to: CGPoint(x: side * 0.53, y: side * 0.63))
    bolt.addLine(to: CGPoint(x: side * 0.45, y: side * 0.78))
    bolt.addLine(to: CGPoint(x: side * 0.56, y: side * 0.74))
    bolt.addLine(to: CGPoint(x: side * 0.50, y: side * 0.88))
    bolt.addLine(to: CGPoint(x: side * 0.66, y: side * 0.68))
    bolt.addLine(to: CGPoint(x: side * 0.56, y: side * 0.71))
    bolt.closeSubpath()
    context.setFillColor(color(0.94, 0.56, 0.23).cgColor)
    context.addPath(bolt)
    context.fillPath()

    context.restoreGState()
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
