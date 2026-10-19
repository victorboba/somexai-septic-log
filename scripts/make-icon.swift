#!/usr/bin/env swift
// Renders a 1024x1024 App Store icon from a few parameters, no design tools needed.
//
//   swift scripts/make-icon.swift --out <path.png> --glyph capsule-check --bg 4A55A2 --bg2 7B6BE0 [--glyph-color FFFFFF] [--badge 34C759]
//
// Glyphs (all drawn with CoreGraphics paths, no SF Symbols, which Apple's license forbids in icons):
//   capsule-check   a tilted capsule with a check badge (dose taken)
//   clipboard-check a clipboard with a check (inspection, log)
//   timer-ring      a ring with a thick arc (timers, wear-time)
//   ruler-tape      a curved tape (measurements)
//   drop            a drop with a check (fluids, donations)
//   drop-dollar     a drop with a dollar sign (paid donations)
//   drop-ledger     a ruled ledger card with a drop and dollar sign in front (paid donations, earnings)
//   sheet-lines     a document with lines and a check (reports, hours)
//   route           a road from a stop to a destination pin (trips, mileage)
//   tally           four strokes with a diagonal (counting, data collection)
//   steps-down      four descending bars (tapers, step-down schedules)
//   syringe         a feeding syringe with graduations (tube feeding, fluids)
//   syringe-drop    a feeding syringe beside a drop (tube feeding; two elements)
//   two-cards       a task card with a check, an arrow, and a reward card with a star (first-then boards)
//   thermo-log      a thermometer in front of a ticked clipboard log (temperature and compliance logs)
//   hat-ring        a hard hat inside a progress ring (trade hours, apprenticeship progress)
//   card-stack      a fanned stack of cards with a flame badge (certifications, fire and EMS)
//   sheet-heart     a ruled page with a heart pinned to the corner (care summaries, handovers)
//   gauge-board     a pressure gauge in front of a clipboard (field testing, readings and reports)
//   chimney-brush   a brick stack with a sweep's rod brush in the flue (chimney work)
//   trap-dipstick   a grease interceptor in section with a graduated dipstick (FOG, tanks with layers)
//   tank-record     a buried tank with riser lids in front of a record card (septic, buried assets)
// The background is a diagonal gradient from --bg (bottom-right) to --bg2 (top-left).
// Apple applies the rounded mask itself, so the PNG is a full square with no transparency.

import AppKit
import CoreGraphics
import Foundation

func arg(_ name: String, _ fallback: String) -> String {
    let args = CommandLine.arguments
    if let i = args.firstIndex(of: name), i + 1 < args.count { return args[i + 1] }
    return fallback
}

func color(_ hex: String) -> CGColor {
    var h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
    let v = UInt32(h, radix: 16) ?? 0
    return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

let out = arg("--out", "AppIcon.png")
let glyph = arg("--glyph", "capsule-check")
let bg1 = color(arg("--bg", "4A55A2"))
let bg2 = color(arg("--bg2", "7B6BE0"))
let glyphColor = color(arg("--glyph-color", "FFFFFF"))
let badgeColor = color(arg("--badge", "34C759"))
let size: CGFloat = 1024

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("Could not create context")
}

// Background gradient
let gradient = CGGradient(colorsSpace: space, colors: [bg2, bg1] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// Soft highlight in the top-left so the icon reads as lit, not flat
let highlight = CGGradient(colorsSpace: space, colors: [CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.18), CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(highlight, startCenter: CGPoint(x: size * 0.25, y: size * 0.8), startRadius: 0, endCenter: CGPoint(x: size * 0.25, y: size * 0.8), endRadius: size * 0.9, options: [])

func shadow(_ on: Bool) {
    if on { ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.22)) }
    else { ctx.setShadow(offset: .zero, blur: 0, color: nil) }
}

func checkBadge(center: CGPoint, radius: CGFloat) {
    shadow(true)
    ctx.setFillColor(badgeColor)
    ctx.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    shadow(false)
    // white ring
    ctx.setStrokeColor(glyphColor)
    ctx.setLineWidth(radius * 0.16)
    ctx.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2).insetBy(dx: radius * 0.08, dy: radius * 0.08))
    // check
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(radius * 0.22)
    ctx.move(to: CGPoint(x: center.x - radius * 0.42, y: center.y - radius * 0.02))
    ctx.addLine(to: CGPoint(x: center.x - radius * 0.1, y: center.y - radius * 0.34))
    ctx.addLine(to: CGPoint(x: center.x + radius * 0.46, y: center.y + radius * 0.3))
    ctx.strokePath()
}

func capsuleCheck() {
    let length: CGFloat = 560, width: CGFloat = 250
    ctx.saveGState()
    ctx.translateBy(x: size / 2 - 30, y: size / 2 + 30)
    ctx.rotate(by: .pi / 4)
    let rect = CGRect(x: -length / 2, y: -width / 2, width: length, height: width)
    let path = CGPath(roundedRect: rect, cornerWidth: width / 2, cornerHeight: width / 2, transform: nil)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(path)
    ctx.fillPath()
    shadow(false)
    // second half in a translucent tint of the background
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.setFillColor(bg1.copy(alpha: 0.55)!)
    ctx.fill(CGRect(x: 0, y: -width / 2, width: length / 2, height: width))
    ctx.restoreGState()
    // seam
    ctx.setStrokeColor(bg1.copy(alpha: 0.35)!)
    ctx.setLineWidth(10)
    ctx.move(to: CGPoint(x: 0, y: -width / 2))
    ctx.addLine(to: CGPoint(x: 0, y: width / 2))
    ctx.strokePath()
    ctx.restoreGState()
    checkBadge(center: CGPoint(x: size * 0.72, y: size * 0.27), radius: 118)
}

func clipboardCheck() {
    let board = CGRect(x: 262, y: 170, width: 500, height: 640)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: board, cornerWidth: 56, cornerHeight: 56, transform: nil))
    ctx.fillPath()
    shadow(false)
    // clip at the top
    ctx.setFillColor(bg1)
    ctx.addPath(CGPath(roundedRect: CGRect(x: 412, y: 760, width: 200, height: 90), cornerWidth: 30, cornerHeight: 30, transform: nil))
    ctx.fillPath()
    // lines
    ctx.setStrokeColor(bg1.copy(alpha: 0.5)!)
    ctx.setLineCap(.round)
    ctx.setLineWidth(34)
    for y in [640, 540, 440] as [CGFloat] {
        ctx.move(to: CGPoint(x: 340, y: y))
        ctx.addLine(to: CGPoint(x: y == 440 ? 560 : 680, y: y))
        ctx.strokePath()
    }
    checkBadge(center: CGPoint(x: 700, y: 260), radius: 118)
}

func timerRing() {
    let center = CGPoint(x: size / 2, y: size / 2 - 10)
    shadow(true)
    ctx.setStrokeColor(glyphColor.copy(alpha: 0.35)!)
    ctx.setLineWidth(92)
    ctx.addArc(center: center, radius: 300, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
    shadow(false)
    ctx.setStrokeColor(glyphColor)
    ctx.setLineCap(.round)
    ctx.setLineWidth(92)
    ctx.addArc(center: center, radius: 300, startAngle: .pi / 2, endAngle: -.pi * 0.9, clockwise: true)
    ctx.strokePath()
    ctx.setFillColor(glyphColor)
    ctx.fillEllipse(in: CGRect(x: center.x - 40, y: center.y - 40, width: 80, height: 80))
    ctx.setLineWidth(44)
    ctx.move(to: center)
    ctx.addLine(to: CGPoint(x: center.x + 150, y: center.y + 110))
    ctx.strokePath()
}

func rulerTape() {
    shadow(true)
    ctx.setStrokeColor(glyphColor)
    ctx.setLineCap(.round)
    ctx.setLineWidth(150)
    ctx.move(to: CGPoint(x: 190, y: 330))
    ctx.addCurve(to: CGPoint(x: 834, y: 690), control1: CGPoint(x: 330, y: 760), control2: CGPoint(x: 700, y: 260))
    ctx.strokePath()
    shadow(false)
    ctx.setStrokeColor(bg1)
    ctx.setLineWidth(18)
    ctx.setLineCap(.round)
    let pts: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(300, 440, 300, 500), (420, 512, 420, 560), (540, 520, 540, 580), (660, 500, 660, 548), (770, 560, 770, 620)]
    for p in pts { ctx.move(to: CGPoint(x: p.0, y: p.1)); ctx.addLine(to: CGPoint(x: p.2, y: p.3)); ctx.strokePath() }
}

func drop() {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 512, y: 880))
    path.addCurve(to: CGPoint(x: 232, y: 400), control1: CGPoint(x: 400, y: 700), control2: CGPoint(x: 232, y: 560))
    path.addArc(center: CGPoint(x: 512, y: 400), radius: 280, startAngle: .pi, endAngle: 0, clockwise: false)
    path.addCurve(to: CGPoint(x: 512, y: 880), control1: CGPoint(x: 792, y: 560), control2: CGPoint(x: 624, y: 700))
    path.closeSubpath()
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(path)
    ctx.fillPath()
    shadow(false)
    checkBadge(center: CGPoint(x: 740, y: 250), radius: 118)
}

func dropPath(cx: CGFloat, top: CGFloat, r: CGFloat) -> CGPath {
    // A teardrop: point at the top, circle of radius r whose center sits 1.7r below the point.
    let cy = top - 1.7 * r
    let path = CGMutablePath()
    path.move(to: CGPoint(x: cx, y: top))
    path.addCurve(to: CGPoint(x: cx - r, y: cy), control1: CGPoint(x: cx - 0.4 * r, y: top - 0.65 * r), control2: CGPoint(x: cx - r, y: cy + 0.55 * r))
    path.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .pi, endAngle: 0, clockwise: false)
    path.addCurve(to: CGPoint(x: cx, y: top), control1: CGPoint(x: cx + r, y: cy + 0.55 * r), control2: CGPoint(x: cx + 0.4 * r, y: top - 0.65 * r))
    path.closeSubpath()
    return path
}

func text(_ string: String, size fontSize: CGFloat, weight: NSFont.Weight, color: CGColor, center: CGPoint) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(cgColor: color)!]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
    let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
    ctx.saveGState()
    ctx.textPosition = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

/// A ledger card with ruled lines behind a drop that carries a dollar sign (paid plasma donation).
func dropLedger() {
    let card = CGRect(x: 300, y: 130, width: 560, height: 680)
    shadow(true)
    ctx.setFillColor(glyphColor.copy(alpha: 0.92)!)
    ctx.addPath(CGPath(roundedRect: card, cornerWidth: 56, cornerHeight: 56, transform: nil))
    ctx.fillPath()
    shadow(false)
    ctx.setStrokeColor(bg1.copy(alpha: 0.35)!)
    ctx.setLineCap(.round)
    ctx.setLineWidth(30)
    for y in [700, 600, 500, 400, 300] as [CGFloat] {
        ctx.move(to: CGPoint(x: 560, y: y))
        ctx.addLine(to: CGPoint(x: 790, y: y))
        ctx.strokePath()
    }
    ctx.setLineWidth(22)
    ctx.setStrokeColor(bg1.copy(alpha: 0.55)!)
    ctx.move(to: CGPoint(x: 560, y: 220)); ctx.addLine(to: CGPoint(x: 790, y: 220)); ctx.strokePath()
    // The drop overlaps the card's left edge so the two read as one object.
    let drop = dropPath(cx: 372, top: 900, r: 210)
    shadow(true)
    ctx.setFillColor(bg1)
    ctx.addPath(drop); ctx.fillPath()
    shadow(false)
    ctx.setStrokeColor(glyphColor)
    ctx.setLineWidth(26)
    ctx.addPath(drop); ctx.strokePath()
    text("$", size: 300, weight: .heavy, color: glyphColor, center: CGPoint(x: 372, y: 520))
}

/// A single large drop with a dollar sign inside.
func dropDollar() {
    let drop = dropPath(cx: 512, top: 930, r: 290)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(drop); ctx.fillPath()
    shadow(false)
    text("$", size: 400, weight: .heavy, color: bg1, center: CGPoint(x: 512, y: 420))
}

/// A road between two stops with a location pin at the destination (trips, mileage).
func route() {
    shadow(true)
    ctx.setStrokeColor(glyphColor)
    ctx.setLineCap(.round)
    ctx.setLineWidth(70)
    ctx.setLineDash(phase: 0, lengths: [0.1, 130])
    ctx.move(to: CGPoint(x: 230, y: 250))
    ctx.addCurve(to: CGPoint(x: 720, y: 690), control1: CGPoint(x: 560, y: 230), control2: CGPoint(x: 380, y: 720))
    ctx.strokePath()
    ctx.setLineDash(phase: 0, lengths: [])
    // Start stop
    ctx.setFillColor(glyphColor)
    ctx.fillEllipse(in: CGRect(x: 150, y: 170, width: 160, height: 160))
    shadow(false)
    ctx.setFillColor(bg1)
    ctx.fillEllipse(in: CGRect(x: 200, y: 220, width: 60, height: 60))
    // Destination pin
    shadow(true)
    let pin = CGMutablePath()
    pin.move(to: CGPoint(x: 720, y: 560))
    pin.addCurve(to: CGPoint(x: 580, y: 780), control1: CGPoint(x: 660, y: 640), control2: CGPoint(x: 580, y: 690))
    pin.addArc(center: CGPoint(x: 720, y: 780), radius: 140, startAngle: .pi, endAngle: 0, clockwise: true)
    pin.addCurve(to: CGPoint(x: 720, y: 560), control1: CGPoint(x: 860, y: 690), control2: CGPoint(x: 780, y: 640))
    pin.closeSubpath()
    ctx.setFillColor(glyphColor)
    ctx.addPath(pin); ctx.fillPath()
    shadow(false)
    ctx.setFillColor(bg1)
    ctx.fillEllipse(in: CGRect(x: 665, y: 725, width: 110, height: 110))
}

/// Four tally strokes with a diagonal across them (counting, data collection).
func tally() {
    shadow(true)
    ctx.setStrokeColor(glyphColor)
    ctx.setLineCap(.round)
    ctx.setLineWidth(66)
    let top: CGFloat = 740, bottom: CGFloat = 300
    for i in 0..<4 {
        let x = 250 + CGFloat(i) * 145
        ctx.move(to: CGPoint(x: x, y: bottom))
        ctx.addLine(to: CGPoint(x: x, y: top))
    }
    ctx.strokePath()
    ctx.setLineWidth(62)
    ctx.move(to: CGPoint(x: 200, y: bottom + 60))
    ctx.addLine(to: CGPoint(x: 735, y: top - 60))
    ctx.strokePath()
    shadow(false)
}

/// Four bars descending left to right, like a step-down schedule.
func stepsDown() {
    shadow(true)
    ctx.setFillColor(glyphColor)
    let heights: [CGFloat] = [620, 480, 350, 250]
    let width: CGFloat = 150, gap: CGFloat = 32
    let totalWidth = width * 4 + gap * 3
    var x = (1024 - totalWidth) / 2
    for h in heights {
        let rect = CGRect(x: x, y: 230, width: width, height: h)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 34, cornerHeight: 34, transform: nil))
        ctx.fillPath()
        x += width + gap
    }
    shadow(false)
}

/// A feeding syringe: barrel with graduations, tip and plunger (tube feeding).
func syringe() {
    shadow(true)
    ctx.setFillColor(glyphColor)
    // Barrel
    ctx.addPath(CGPath(roundedRect: CGRect(x: 370, y: 210, width: 284, height: 520), cornerWidth: 40, cornerHeight: 40, transform: nil))
    ctx.fillPath()
    // Tip below the barrel
    ctx.addPath(CGPath(roundedRect: CGRect(x: 472, y: 120, width: 80, height: 110), cornerWidth: 30, cornerHeight: 30, transform: nil))
    ctx.fillPath()
    // Plunger rod and flange above it
    ctx.addPath(CGPath(roundedRect: CGRect(x: 472, y: 700, width: 80, height: 150), cornerWidth: 26, cornerHeight: 26, transform: nil))
    ctx.fillPath()
    ctx.addPath(CGPath(roundedRect: CGRect(x: 350, y: 820, width: 324, height: 70), cornerWidth: 34, cornerHeight: 34, transform: nil))
    ctx.fillPath()
    shadow(false)
    // Graduation marks cut into the barrel
    ctx.setStrokeColor(bg1)
    ctx.setLineCap(.round)
    ctx.setLineWidth(26)
    for y in [330, 430, 530, 630] as [CGFloat] {
        ctx.move(to: CGPoint(x: 430, y: y))
        ctx.addLine(to: CGPoint(x: 560, y: y))
        ctx.strokePath()
    }
}

/// A feeding syringe with a drop beside it: two elements so the icon does not read as a single shape.
func syringeDrop() {
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: CGRect(x: 210, y: 300, width: 250, height: 440), cornerWidth: 36, cornerHeight: 36, transform: nil))
    ctx.fillPath()
    ctx.addPath(CGPath(roundedRect: CGRect(x: 300, y: 218, width: 70, height: 100), cornerWidth: 26, cornerHeight: 26, transform: nil))
    ctx.fillPath()
    ctx.addPath(CGPath(roundedRect: CGRect(x: 300, y: 715, width: 70, height: 130), cornerWidth: 24, cornerHeight: 24, transform: nil))
    ctx.fillPath()
    ctx.addPath(CGPath(roundedRect: CGRect(x: 195, y: 820, width: 280, height: 62), cornerWidth: 30, cornerHeight: 30, transform: nil))
    ctx.fillPath()
    let drop = dropPath(cx: 700, top: 690, r: 165)
    ctx.addPath(drop)
    ctx.fillPath()
    shadow(false)
    ctx.setStrokeColor(bg1)
    ctx.setLineCap(.round)
    ctx.setLineWidth(24)
    for y in [400, 490, 580, 670] as [CGFloat] {
        ctx.move(to: CGPoint(x: 265, y: y))
        ctx.addLine(to: CGPoint(x: 380, y: y))
        ctx.strokePath()
    }
    ctx.setFillColor(bg1)
    ctx.fillEllipse(in: CGRect(x: 655, y: 385, width: 90, height: 90))
}

func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat) -> CGPath {
    let path = CGMutablePath()
    for i in 0..<10 {
        let radius = i % 2 == 0 ? outer : inner
        let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y - sin(angle) * radius)
        if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
}

/// Two board cards: the task on the left with a check, the reward on the right with a star,
/// and an arrow between them. Three elements, so the icon still reads at 40 points.
func twoCards() {
    let cardWidth: CGFloat = 336, cardHeight: CGFloat = 430
    let top = size / 2 + cardHeight / 2
    let left = CGRect(x: 92, y: top - cardHeight, width: cardWidth, height: cardHeight)
    let right = CGRect(x: size - 92 - cardWidth, y: top - cardHeight, width: cardWidth, height: cardHeight)

    for card in [left, right] {
        shadow(true)
        ctx.setFillColor(glyphColor)
        ctx.addPath(CGPath(roundedRect: card, cornerWidth: 58, cornerHeight: 58, transform: nil))
        ctx.fillPath()
        shadow(false)
    }

    // The task card carries a check.
    ctx.setStrokeColor(badgeColor)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(58)
    let checkCenter = CGPoint(x: left.midX, y: left.midY)
    ctx.move(to: CGPoint(x: checkCenter.x - 96, y: checkCenter.y + 8))
    ctx.addLine(to: CGPoint(x: checkCenter.x - 26, y: checkCenter.y - 66))
    ctx.addLine(to: CGPoint(x: checkCenter.x + 100, y: checkCenter.y + 80))
    ctx.strokePath()

    // The reward card carries a star.
    ctx.setFillColor(bg1)
    ctx.addPath(starPath(center: CGPoint(x: right.midX, y: right.midY), outer: 128, inner: 54))
    ctx.fillPath()

    // Arrow from one to the other.
    ctx.setStrokeColor(glyphColor)
    ctx.setLineWidth(34)
    let y = size / 2
    ctx.move(to: CGPoint(x: left.maxX + 34, y: y))
    ctx.addLine(to: CGPoint(x: right.minX - 34, y: y))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: right.minX - 86, y: y + 46))
    ctx.addLine(to: CGPoint(x: right.minX - 34, y: y))
    ctx.addLine(to: CGPoint(x: right.minX - 86, y: y - 46))
    ctx.strokePath()

    // Caption strips under each card so the pair reads as a board, not two buttons.
    ctx.setFillColor(glyphColor.copy(alpha: 0.55)!)
    for card in [left, right] {
        ctx.addPath(CGPath(roundedRect: CGRect(x: card.minX + 52, y: card.minY - 74, width: cardWidth - 104, height: 40),
                           cornerWidth: 20, cornerHeight: 20, transform: nil))
        ctx.fillPath()
    }
}

/// A thermometer beside a clipboard log with a tick: the reading and the record it lands on.
func thermoLog() {
    // The clipboard behind, offset right.
    let board = CGRect(x: 404, y: 196, width: 440, height: 580)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: board, cornerWidth: 52, cornerHeight: 52, transform: nil))
    ctx.fillPath()
    shadow(false)

    // Clip at the top of the board.
    ctx.setFillColor(bg1)
    ctx.addPath(CGPath(roundedRect: CGRect(x: board.midX - 86, y: board.maxY - 42, width: 172, height: 62),
                       cornerWidth: 26, cornerHeight: 26, transform: nil))
    ctx.fillPath()

    // Ruled lines, with the last one ticked.
    ctx.setFillColor(bg1.copy(alpha: 0.28)!)
    var lineY = board.maxY - 150
    for _ in 0..<3 {
        ctx.addPath(CGPath(roundedRect: CGRect(x: board.minX + 62, y: lineY, width: board.width - 190, height: 30),
                           cornerWidth: 15, cornerHeight: 15, transform: nil))
        ctx.fillPath()
        lineY -= 86
    }
    ctx.setStrokeColor(badgeColor)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(34)
    ctx.move(to: CGPoint(x: board.minX + 74, y: lineY + 18))
    ctx.addLine(to: CGPoint(x: board.minX + 126, y: lineY - 26))
    ctx.addLine(to: CGPoint(x: board.minX + 228, y: lineY + 76))
    ctx.strokePath()

    // The thermometer in front, on the left.
    let stemWidth: CGFloat = 96
    let bulbRadius: CGFloat = 88
    let cx: CGFloat = 258
    let bulbY: CGFloat = 284
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.fillEllipse(in: CGRect(x: cx - bulbRadius, y: bulbY - bulbRadius, width: bulbRadius * 2, height: bulbRadius * 2))
    ctx.addPath(CGPath(roundedRect: CGRect(x: cx - stemWidth / 2, y: bulbY, width: stemWidth, height: 456),
                       cornerWidth: stemWidth / 2, cornerHeight: stemWidth / 2, transform: nil))
    ctx.fillPath()
    shadow(false)

    // The mercury inside, and graduation marks down the right of the stem.
    ctx.setFillColor(badgeColor)
    ctx.fillEllipse(in: CGRect(x: cx - 56, y: bulbY - 56, width: 112, height: 112))
    ctx.addPath(CGPath(roundedRect: CGRect(x: cx - 26, y: bulbY, width: 52, height: 300),
                       cornerWidth: 26, cornerHeight: 26, transform: nil))
    ctx.fillPath()

    ctx.setStrokeColor(bg1.copy(alpha: 0.55)!)
    ctx.setLineWidth(14)
    var markY = bulbY + 220
    for _ in 0..<4 {
        ctx.move(to: CGPoint(x: cx + 12, y: markY))
        ctx.addLine(to: CGPoint(x: cx + 34, y: markY))
        ctx.strokePath()
        markY += 62
    }
}

/// A hard hat inside a progress ring: the trade and the hours, two elements that read at any size.
func hatRing() {
    let centre = CGPoint(x: size / 2, y: size / 2)
    let ringRadius: CGFloat = 338
    let lineWidth: CGFloat = 78

    // Track, then the filled arc from the top round to about three quarters.
    ctx.setLineCap(.round)
    ctx.setStrokeColor(glyphColor.copy(alpha: 0.26)!)
    ctx.setLineWidth(lineWidth)
    ctx.addArc(center: centre, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()

    ctx.setStrokeColor(badgeColor)
    ctx.setLineWidth(lineWidth)
    ctx.addArc(center: centre, radius: ringRadius, startAngle: .pi / 2, endAngle: -.pi / 3, clockwise: true)
    ctx.strokePath()

    // The hat: a dome with its flat side down, on a brim that overhangs it.
    let domeBase: CGFloat = centre.y - 34
    let domeRadius: CGFloat = 168
    let brimHeight: CGFloat = 58
    let brimWidth: CGFloat = 466

    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.move(to: CGPoint(x: centre.x - domeRadius, y: domeBase))
    ctx.addArc(center: CGPoint(x: centre.x, y: domeBase), radius: domeRadius,
               startAngle: .pi, endAngle: 0, clockwise: true)
    ctx.closePath()
    ctx.fillPath()
    ctx.addPath(CGPath(roundedRect: CGRect(x: centre.x - brimWidth / 2, y: domeBase - brimHeight,
                                           width: brimWidth, height: brimHeight),
                       cornerWidth: brimHeight / 2, cornerHeight: brimHeight / 2, transform: nil))
    ctx.fillPath()
    shadow(false)

    // Two ridges over the crown so it reads as a hard hat.
    ctx.setStrokeColor(bg1.copy(alpha: 0.42)!)
    ctx.setLineWidth(20)
    ctx.setLineCap(.round)
    for offset in [CGFloat(-66), CGFloat(66)] {
        ctx.move(to: CGPoint(x: centre.x + offset * 1.12, y: domeBase + 18))
        ctx.addCurve(to: CGPoint(x: centre.x + offset * 0.34, y: domeBase + domeRadius - 20),
                     control1: CGPoint(x: centre.x + offset * 1.08, y: domeBase + 96),
                     control2: CGPoint(x: centre.x + offset * 0.72, y: domeBase + domeRadius - 62))
        ctx.strokePath()
    }
}

/// A stack of cards with a flame badge: the wallet of certifications and the trade it belongs to.
func cardStack() {
    let cx = size / 2
    // Two cards behind, fanned, then the front card square on.
    func roundedCard(_ rect: CGRect, rotation: CGFloat, alpha: CGFloat) {
        ctx.saveGState()
        ctx.translateBy(x: rect.midX, y: rect.midY)
        ctx.rotate(by: rotation)
        ctx.translateBy(x: -rect.midX, y: -rect.midY)
        shadow(true)
        ctx.setFillColor(glyphColor.copy(alpha: alpha)!)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 46, cornerHeight: 46, transform: nil))
        ctx.fillPath()
        shadow(false)
        ctx.restoreGState()
    }

    let front = CGRect(x: cx - 300, y: 300, width: 600, height: 392)
    roundedCard(front, rotation: 0.16, alpha: 0.5)
    roundedCard(front, rotation: 0.08, alpha: 0.72)
    roundedCard(front, rotation: 0, alpha: 1)

    // Ruled lines on the front card, the way a licence reads.
    ctx.setFillColor(bg1.copy(alpha: 0.26)!)
    var lineY = front.maxY - 132
    for width in [CGFloat(300), CGFloat(232), CGFloat(176)] {
        ctx.addPath(CGPath(roundedRect: CGRect(x: front.minX + 60, y: lineY, width: width, height: 30),
                           cornerWidth: 15, cornerHeight: 15, transform: nil))
        ctx.fillPath()
        lineY -= 66
    }

    // The flame badge, sitting on the lower right corner of the stack.
    let centre = CGPoint(x: front.maxX - 48, y: front.minY + 36)
    let radius: CGFloat = 128
    shadow(true)
    ctx.setFillColor(badgeColor)
    ctx.fillEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
    shadow(false)

    // A flame, not a drop: the difference is asymmetry. A leaning tip, a bulge on one side,
    // a concave sweep on the other and a second small tongue. A symmetric teardrop reads as water.
    ctx.setFillColor(glyphColor)
    let tip = CGPoint(x: centre.x + 6, y: centre.y + 86)
    let path = CGMutablePath()
    path.move(to: tip)
    path.addCurve(to: CGPoint(x: centre.x + 50, y: centre.y - 18),
                  control1: CGPoint(x: centre.x + 52, y: centre.y + 30),
                  control2: CGPoint(x: centre.x + 58, y: centre.y + 4))
    path.addCurve(to: CGPoint(x: centre.x - 14, y: centre.y - 64),
                  control1: CGPoint(x: centre.x + 44, y: centre.y - 54),
                  control2: CGPoint(x: centre.x + 10, y: centre.y - 70))
    path.addCurve(to: CGPoint(x: centre.x - 40, y: centre.y + 10),
                  control1: CGPoint(x: centre.x - 50, y: centre.y - 54),
                  control2: CGPoint(x: centre.x - 58, y: centre.y - 14))
    path.addCurve(to: CGPoint(x: centre.x - 38, y: centre.y + 56),
                  control1: CGPoint(x: centre.x - 28, y: centre.y + 28),
                  control2: CGPoint(x: centre.x - 30, y: centre.y + 42))
    path.addCurve(to: tip,
                  control1: CGPoint(x: centre.x - 12, y: centre.y + 42),
                  control2: CGPoint(x: centre.x - 2, y: centre.y + 62))
    path.closeSubpath()
    ctx.addPath(path)
    ctx.fillPath()

    // The hot core, low and offset, in the badge colour.
    ctx.setFillColor(badgeColor)
    let inner = CGMutablePath()
    let innerTip = CGPoint(x: centre.x + 2, y: centre.y + 20)
    inner.move(to: innerTip)
    inner.addCurve(to: CGPoint(x: centre.x + 24, y: centre.y - 26),
                   control1: CGPoint(x: centre.x + 20, y: centre.y - 2),
                   control2: CGPoint(x: centre.x + 26, y: centre.y - 12))
    inner.addCurve(to: CGPoint(x: centre.x - 20, y: centre.y - 24),
                   control1: CGPoint(x: centre.x + 20, y: centre.y - 48),
                   control2: CGPoint(x: centre.x - 18, y: centre.y - 48))
    inner.addCurve(to: innerTip,
                   control1: CGPoint(x: centre.x - 22, y: centre.y - 6),
                   control2: CGPoint(x: centre.x - 10, y: centre.y + 4))
    inner.closeSubpath()
    ctx.addPath(inner)
    ctx.fillPath()
}

/// A sheet of paper with a heart pinned to it: the page, and who it is for.
func sheetHeart() {
    let page = CGRect(x: 254, y: 208, width: 516, height: 636)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: page, cornerWidth: 48, cornerHeight: 48, transform: nil))
    ctx.fillPath()
    shadow(false)

    // Ruled lines, the top one short like a heading and the rest full width.
    ctx.setFillColor(bg1.copy(alpha: 0.24)!)
    var lineY = page.maxY - 150
    let widths: [CGFloat] = [200, 356, 356, 300, 356, 248]
    for width in widths {
        ctx.addPath(CGPath(roundedRect: CGRect(x: page.minX + 78, y: lineY, width: width, height: 28),
                           cornerWidth: 14, cornerHeight: 14, transform: nil))
        ctx.fillPath()
        lineY -= 74
    }

    // The heart, overlapping the lower right corner so it reads as pinned on rather than printed.
    let centre = CGPoint(x: page.maxX - 26, y: page.minY + 52)
    let r: CGFloat = 132
    shadow(true)
    ctx.setFillColor(badgeColor)
    let heart = CGMutablePath()
    let bottom = CGPoint(x: centre.x, y: centre.y - r * 0.78)
    heart.move(to: bottom)
    heart.addCurve(to: CGPoint(x: centre.x - r, y: centre.y + r * 0.24),
                   control1: CGPoint(x: centre.x - r * 0.62, y: centre.y - r * 0.30),
                   control2: CGPoint(x: centre.x - r, y: centre.y - r * 0.06))
    heart.addArc(center: CGPoint(x: centre.x - r * 0.5, y: centre.y + r * 0.26),
                 radius: r * 0.5, startAngle: .pi, endAngle: 0, clockwise: true)
    heart.addArc(center: CGPoint(x: centre.x + r * 0.5, y: centre.y + r * 0.26),
                 radius: r * 0.5, startAngle: .pi, endAngle: 0, clockwise: true)
    heart.addCurve(to: bottom,
                   control1: CGPoint(x: centre.x + r, y: centre.y - r * 0.06),
                   control2: CGPoint(x: centre.x + r * 0.62, y: centre.y - r * 0.30))
    heart.closeSubpath()
    ctx.addPath(heart)
    ctx.fillPath()
    shadow(false)
}

/// A pressure gauge in front of a clipboard: the reading and the report it lands on.
func gaugeBoard() {
    // The clipboard, offset back and right.
    let board = CGRect(x: 372, y: 198, width: 470, height: 596)
    shadow(true)
    ctx.setFillColor(glyphColor.copy(alpha: 0.92)!)
    ctx.addPath(CGPath(roundedRect: board, cornerWidth: 50, cornerHeight: 50, transform: nil))
    ctx.fillPath()
    shadow(false)
    ctx.setFillColor(bg1)
    ctx.addPath(CGPath(roundedRect: CGRect(x: board.midX - 84, y: board.maxY - 40, width: 168, height: 58),
                       cornerWidth: 25, cornerHeight: 25, transform: nil))
    ctx.fillPath()
    ctx.setFillColor(bg1.copy(alpha: 0.24)!)
    var lineY = board.maxY - 150
    for width in [CGFloat(250), CGFloat(300), CGFloat(190)] {
        ctx.addPath(CGPath(roundedRect: CGRect(x: board.minX + 54, y: lineY, width: width, height: 28),
                           cornerWidth: 14, cornerHeight: 14, transform: nil))
        ctx.fillPath()
        lineY -= 80
    }

    // The gauge, in front and to the left.
    let centre = CGPoint(x: 372, y: 392)
    let outer: CGFloat = 226
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.fillEllipse(in: CGRect(x: centre.x - outer, y: centre.y - outer, width: outer * 2, height: outer * 2))
    shadow(false)
    ctx.setFillColor(bg1.copy(alpha: 0.14)!)
    ctx.fillEllipse(in: CGRect(x: centre.x - outer + 34, y: centre.y - outer + 34,
                               width: (outer - 34) * 2, height: (outer - 34) * 2))

    // Tick marks around the dial.
    ctx.setStrokeColor(bg1.copy(alpha: 0.55)!)
    ctx.setLineCap(.round)
    ctx.setLineWidth(15)
    for step in 0...8 {
        let angle = CGFloat.pi * 1.25 - CGFloat(step) * (.pi * 1.5 / 8)
        let inner = outer - 88, out = outer - 52
        ctx.move(to: CGPoint(x: centre.x + cos(angle) * inner, y: centre.y + sin(angle) * inner))
        ctx.addLine(to: CGPoint(x: centre.x + cos(angle) * out, y: centre.y + sin(angle) * out))
        ctx.strokePath()
    }

    // The needle, pointing up and right into the healthy part of the dial.
    ctx.setStrokeColor(badgeColor)
    ctx.setLineWidth(26)
    let needle = CGFloat.pi * 0.42
    ctx.move(to: CGPoint(x: centre.x, y: centre.y))
    ctx.addLine(to: CGPoint(x: centre.x + cos(needle) * (outer - 86),
                            y: centre.y + sin(needle) * (outer - 86)))
    ctx.strokePath()
    ctx.setFillColor(badgeColor)
    ctx.fillEllipse(in: CGRect(x: centre.x - 34, y: centre.y - 34, width: 68, height: 68))
}

func sheetLines() {
    let sheet = CGRect(x: 262, y: 150, width: 500, height: 700)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: sheet, cornerWidth: 48, cornerHeight: 48, transform: nil))
    ctx.fillPath()
    shadow(false)
    ctx.setStrokeColor(bg1.copy(alpha: 0.5)!)
    ctx.setLineCap(.round)
    ctx.setLineWidth(34)
    for (i, y) in ([720, 620, 520, 420] as [CGFloat]).enumerated() {
        ctx.move(to: CGPoint(x: 340, y: y))
        ctx.addLine(to: CGPoint(x: i == 3 ? 540 : 684, y: y))
        ctx.strokePath()
    }
    checkBadge(center: CGPoint(x: 700, y: 250), radius: 118)
}

/// A brick chimney stack with a sweep's rod brush going down the flue.
func chimneyBrush() {
    let stack = CGRect(x: 250, y: 96, width: 360, height: 470)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: stack, cornerWidth: 24, cornerHeight: 24, transform: nil))
    ctx.fillPath()
    let crown = CGRect(x: 208, y: 556, width: 444, height: 70)
    ctx.addPath(CGPath(roundedRect: crown, cornerWidth: 20, cornerHeight: 20, transform: nil))
    ctx.fillPath()
    shadow(false)

    // Brick courses, staggered the way they are actually laid.
    ctx.setStrokeColor(bg1.copy(alpha: 0.30)!)
    ctx.setLineWidth(13)
    var courseY = stack.minY + 72
    var stagger = false
    while courseY < stack.maxY - 24 {
        ctx.move(to: CGPoint(x: stack.minX + 20, y: courseY))
        ctx.addLine(to: CGPoint(x: stack.maxX - 20, y: courseY))
        ctx.strokePath()
        let joint = stagger ? stack.midX - 90 : stack.midX + 90
        ctx.move(to: CGPoint(x: joint, y: courseY))
        ctx.addLine(to: CGPoint(x: joint, y: min(courseY + 84, stack.maxY - 24)))
        ctx.strokePath()
        courseY += 84
        stagger.toggle()
    }

    // The flue, dark, so the brush is visibly going into something.
    ctx.setFillColor(bg1.copy(alpha: 0.72)!)
    ctx.addPath(CGPath(roundedRect: CGRect(x: stack.midX - 88, y: crown.minY - 34, width: 176, height: 104),
                       cornerWidth: 18, cornerHeight: 18, transform: nil))
    ctx.fillPath()

    // The rod and its brush head, drawn along one axis so the bristles sit across the
    // rod rather than radiating from a point.
    ctx.saveGState()
    ctx.translateBy(x: stack.midX, y: crown.minY + 26)
    ctx.rotate(by: -.pi / 5)
    ctx.setStrokeColor(badgeColor)
    ctx.setLineCap(.round)
    ctx.setLineWidth(30)
    ctx.move(to: .zero)
    ctx.addLine(to: CGPoint(x: 0, y: 372))
    ctx.strokePath()

    ctx.setStrokeColor(glyphColor)
    ctx.setLineWidth(16)
    var along: CGFloat = 112
    while along <= 300 {
        ctx.move(to: CGPoint(x: -118, y: along))
        ctx.addLine(to: CGPoint(x: 118, y: along))
        ctx.strokePath()
        along += 40
    }
    ctx.setFillColor(badgeColor)
    ctx.addPath(CGPath(roundedRect: CGRect(x: -26, y: 88, width: 52, height: 236),
                       cornerWidth: 26, cornerHeight: 26, transform: nil))
    ctx.fillPath()
    ctx.restoreGState()
}

/// A grease interceptor in section, with the dipstick that measures it.
func trapDipstick() {
    let tank = CGRect(x: 150, y: 250, width: 640, height: 470)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: tank, cornerWidth: 44, cornerHeight: 44, transform: nil))
    ctx.fillPath()
    shadow(false)

    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: tank, cornerWidth: 44, cornerHeight: 44, transform: nil))
    ctx.clip()
    // The grease cap floating on top, and the sludge that settles under it: the two
    // layers the quarter rule adds together.
    ctx.setFillColor(badgeColor)
    ctx.fill(CGRect(x: tank.minX, y: tank.maxY - 126, width: tank.width, height: 126))
    ctx.setFillColor(bg1.copy(alpha: 0.30)!)
    ctx.fill(CGRect(x: tank.minX, y: tank.minY, width: tank.width, height: 92))
    // Inlet and outlet tees.
    ctx.setStrokeColor(bg1.copy(alpha: 0.72)!)
    ctx.setLineWidth(38)
    ctx.setLineCap(.butt)
    for x in [tank.minX + 104, tank.maxX - 104] {
        ctx.move(to: CGPoint(x: x, y: tank.maxY))
        ctx.addLine(to: CGPoint(x: x, y: tank.minY + 120))
        ctx.strokePath()
    }
    ctx.restoreGState()
    // A rim, so the tank reads as a container rather than a striped card.
    ctx.setStrokeColor(bg1.copy(alpha: 0.55)!)
    ctx.setLineWidth(18)
    ctx.addPath(CGPath(roundedRect: tank.insetBy(dx: 9, dy: 9), cornerWidth: 36, cornerHeight: 36, transform: nil))
    ctx.strokePath()

    // The dipstick, pushed down through the grease, graduated like a sludge judge.
    ctx.saveGState()
    ctx.translateBy(x: 690, y: 540)
    ctx.rotate(by: -.pi / 14)
    shadow(true)
    ctx.setFillColor(glyphColor)
    let stick = CGPath(roundedRect: CGRect(x: -36, y: -330, width: 72, height: 680),
                       cornerWidth: 36, cornerHeight: 36, transform: nil)
    ctx.addPath(stick)
    ctx.fillPath()
    shadow(false)
    ctx.setStrokeColor(bg1.copy(alpha: 0.55)!)
    ctx.setLineWidth(14)
    ctx.addPath(stick)
    ctx.strokePath()
    ctx.setStrokeColor(bg1.copy(alpha: 0.65)!)
    ctx.setLineCap(.round)
    ctx.setLineWidth(12)
    var tick: CGFloat = -250
    var long = true
    while tick < 300 {
        ctx.move(to: CGPoint(x: -22, y: tick))
        ctx.addLine(to: CGPoint(x: long ? 24 : 2, y: tick))
        ctx.strokePath()
        tick += 58
        long.toggle()
    }
    ctx.restoreGState()
}

/// A septic tank in section, in front of the card its record is kept on.
func tankRecord() {
    // The record card, behind and to the right.
    let card = CGRect(x: 420, y: 230, width: 430, height: 560)
    shadow(true)
    ctx.setFillColor(glyphColor.copy(alpha: 0.84)!)
    ctx.addPath(CGPath(roundedRect: card, cornerWidth: 46, cornerHeight: 46, transform: nil))
    ctx.fillPath()
    shadow(false)
    ctx.setFillColor(badgeColor)
    ctx.addPath(CGPath(roundedRect: CGRect(x: card.minX, y: card.maxY - 96, width: card.width, height: 96),
                       cornerWidth: 46, cornerHeight: 46, transform: nil))
    ctx.fillPath()
    ctx.fill(CGRect(x: card.minX, y: card.maxY - 110, width: card.width, height: 60))
    ctx.setFillColor(bg1.copy(alpha: 0.22)!)
    var lineY = card.maxY - 190
    for width in [CGFloat(250), CGFloat(300), CGFloat(210), CGFloat(280)] {
        ctx.addPath(CGPath(roundedRect: CGRect(x: card.minX + 46, y: lineY, width: width, height: 26),
                           cornerWidth: 13, cornerHeight: 13, transform: nil))
        ctx.fillPath()
        lineY -= 74
    }

    // The ground the tank is buried in, so the lids read as the only part you ever see.
    ctx.setFillColor(bg1.copy(alpha: 0.35)!)
    ctx.fill(CGRect(x: 0, y: 560, width: size, height: 26))

    // The tank, in front and to the left, with two risers breaking that line.
    let tank = CGRect(x: 96, y: 210, width: 480, height: 330)
    shadow(true)
    ctx.setFillColor(glyphColor)
    ctx.addPath(CGPath(roundedRect: tank, cornerWidth: 46, cornerHeight: 46, transform: nil))
    ctx.fillPath()
    shadow(false)
    ctx.setStrokeColor(bg1.copy(alpha: 0.45)!)
    ctx.setLineWidth(16)
    ctx.addPath(CGPath(roundedRect: tank.insetBy(dx: 8, dy: 8), cornerWidth: 38, cornerHeight: 38, transform: nil))
    ctx.strokePath()
    for x in [tank.minX + 116, tank.maxX - 116] {
        ctx.setFillColor(glyphColor)
        ctx.addPath(CGPath(roundedRect: CGRect(x: x - 58, y: tank.maxY - 20, width: 116, height: 130),
                           cornerWidth: 16, cornerHeight: 16, transform: nil))
        ctx.fillPath()
        shadow(true)
        ctx.setFillColor(badgeColor)
        ctx.addPath(CGPath(roundedRect: CGRect(x: x - 82, y: tank.maxY + 96, width: 164, height: 46),
                           cornerWidth: 23, cornerHeight: 23, transform: nil))
        ctx.fillPath()
        shadow(false)
    }

    // Liquid level, and the sludge on the floor of the tank.
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: tank, cornerWidth: 46, cornerHeight: 46, transform: nil))
    ctx.clip()
    ctx.setFillColor(bg1.copy(alpha: 0.22)!)
    ctx.fill(CGRect(x: tank.minX, y: tank.minY, width: tank.width, height: 196))
    ctx.setFillColor(bg1.copy(alpha: 0.40)!)
    ctx.fill(CGRect(x: tank.minX, y: tank.minY, width: tank.width, height: 76))
    ctx.restoreGState()
}

switch glyph {
case "capsule-check": capsuleCheck()
case "clipboard-check": clipboardCheck()
case "timer-ring": timerRing()
case "ruler-tape": rulerTape()
case "drop": drop()
case "drop-dollar": dropDollar()
case "drop-ledger": dropLedger()
case "sheet-lines": sheetLines()
case "route": route()
case "tally": tally()
case "steps-down": stepsDown()
case "syringe": syringe()
case "syringe-drop": syringeDrop()
case "two-cards": twoCards()
case "thermo-log": thermoLog()
case "hat-ring": hatRing()
case "card-stack": cardStack()
case "sheet-heart": sheetHeart()
case "gauge-board": gaugeBoard()
case "chimney-brush": chimneyBrush()
case "trap-dipstick": trapDipstick()
case "tank-record": tankRecord()
default: fatalError("Unknown glyph \(glyph)")
}

guard let image = ctx.makeImage() else { fatalError("Could not render") }
let url = URL(fileURLWithPath: out)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { fatalError("Could not write \(out)") }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Could not finalize \(out)") }
print("wrote \(out)")
