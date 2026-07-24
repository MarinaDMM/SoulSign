//
//  NatalChartView.swift
//  SoulSign
//

import SwiftUI

struct NatalChartView: View {
    let matrix: DestinyMatrix
    @EnvironmentObject var loc: LocalizationManager

    private let zodiacGlyphs = ["♈","♉","♊","♋","♌","♍","♎","♏","♐","♑","♒","♓"]

    // Element-based colours: Fire, Earth, Air, Water × 3
    private let segmentColors: [Color] = [
        Color(hue: 0.02, saturation: 0.75, brightness: 0.55),  // Aries   – Fire
        Color(hue: 0.27, saturation: 0.55, brightness: 0.38),  // Taurus  – Earth
        Color(hue: 0.57, saturation: 0.60, brightness: 0.52),  // Gemini  – Air
        Color(hue: 0.67, saturation: 0.65, brightness: 0.48),  // Cancer  – Water
        Color(hue: 0.06, saturation: 0.75, brightness: 0.55),  // Leo     – Fire
        Color(hue: 0.30, saturation: 0.55, brightness: 0.38),  // Virgo   – Earth
        Color(hue: 0.57, saturation: 0.60, brightness: 0.52),  // Libra   – Air
        Color(hue: 0.70, saturation: 0.65, brightness: 0.48),  // Scorpio – Water
        Color(hue: 0.04, saturation: 0.75, brightness: 0.55),  // Sag     – Fire
        Color(hue: 0.29, saturation: 0.55, brightness: 0.38),  // Cap     – Earth
        Color(hue: 0.56, saturation: 0.60, brightness: 0.52),  // Aqua    – Air
        Color(hue: 0.68, saturation: 0.65, brightness: 0.48),  // Pisces  – Water
    ]

    var body: some View {
        VStack(spacing: 10) {
            Text(loc.t("natal_chart"))
                .font(.title3.weight(.semibold))
                .foregroundColor(.white.opacity(0.85))

            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let ctr = CGPoint(x: cx, y: cy)
                let maxR = min(cx, cy) - 2

                // Ring radii
                let R1 = maxR           // outer rim
                let R2 = maxR * 0.83   // inner edge of zodiac band
                let R3 = maxR * 0.67   // outer node ring (cardinals + edge midpoints)
                let R4 = maxR * 0.39   // inner midpoint ring

                // Convert degrees (0° = top, clockwise) → CGPoint on a ring
                func pt(_ deg: Double, _ r: CGFloat) -> CGPoint {
                    let rad = (deg - 90) * .pi / 180
                    return CGPoint(x: cx + r * cos(rad), y: cy + r * sin(rad))
                }

                // ── Background fill ──────────────────────────────────────────
                let bg = Path(ellipseIn: CGRect(x: cx-R1, y: cy-R1, width: R1*2, height: R1*2))
                context.fill(bg, with: .color(Color(hue: 0.67, saturation: 0.35, brightness: 0.11)))

                // ── 12 zodiac segments ───────────────────────────────────────
                for i in 0..<12 {
                    let s = Double(i) * 30
                    let e = s + 30
                    var seg = Path()
                    seg.move(to: pt(s, R1))
                    seg.addArc(center: ctr, radius: R1,
                               startAngle: .degrees(s - 90), endAngle: .degrees(e - 90),
                               clockwise: false)
                    seg.addArc(center: ctr, radius: R2,
                               startAngle: .degrees(e - 90), endAngle: .degrees(s - 90),
                               clockwise: true)
                    seg.closeSubpath()
                    context.fill(seg, with: .color(segmentColors[i].opacity(0.55)))

                    // Zodiac glyph at segment centre
                    context.draw(
                        Text(zodiacGlyphs[i])
                            .font(.system(size: maxR * 0.075))
                            .foregroundColor(.white.opacity(0.72)),
                        at: pt(s + 15, (R1 + R2) / 2), anchor: .center
                    )
                }

                // ── House divider lines (12 spokes) ──────────────────────────
                for i in 0..<12 {
                    var line = Path()
                    line.move(to: pt(Double(i) * 30, R2))
                    line.addLine(to: ctr)
                    context.stroke(line, with: .color(.white.opacity(0.12)), lineWidth: 0.7)
                }

                // ── Concentric circles ───────────────────────────────────────
                for r in [R1, R2, R3, R4] {
                    let c = Path(ellipseIn: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2))
                    context.stroke(c, with: .color(.white.opacity(0.22)), lineWidth: 0.8)
                }

                // ── House numbers ────────────────────────────────────────────
                let romanNumerals = ["I","II","III","IV","V","VI",
                                     "VII","VIII","IX","X","XI","XII"]
                let houseR = maxR * 0.78  // sits between zodiac band and node ring
                for (i, numeral) in romanNumerals.enumerated() {
                    let deg = Double(i) * 30 + 15   // centre of each house segment
                    context.draw(
                        Text(numeral)
                            .font(.system(size: maxR * 0.055, weight: .medium))
                            .foregroundColor(.white.opacity(0.60)),
                        at: pt(deg, houseR), anchor: .center
                    )
                }

                // ── Node positions ───────────────────────────────────────────
                let pA  = pt(0,   R3)   // top    – day
                let pB  = pt(90,  R3)   // right  – month
                let pC  = pt(180, R3)   // bottom – year
                let pD  = pt(270, R3)   // left   – synthesis
                let pAB = pt(45,  R3)
                let pBC = pt(135, R3)
                let pCD = pt(225, R3)
                let pDA = pt(315, R3)
                let pAE = pt(0,   R4)
                let pBE = pt(90,  R4)
                let pCE = pt(180, R4)
                let pDE = pt(270, R4)
                let pE  = ctr

                // ── Aspect lines ─────────────────────────────────────────────
                func aspect(_ a: CGPoint, _ b: CGPoint, alpha: Double = 0.25) {
                    var p = Path(); p.move(to: a); p.addLine(to: b)
                    context.stroke(p, with: .color(.white.opacity(alpha)), lineWidth: 1)
                }
                aspect(pA, pC);   aspect(pB, pD)           // oppositions
                aspect(pA, pB);   aspect(pB, pC)           // squares
                aspect(pC, pD);   aspect(pD, pA)
                aspect(pAB, pCD); aspect(pBC, pDA)         // cross diagonals
                aspect(pE, pAE);  aspect(pE, pBE)          // inner spokes
                aspect(pE, pCE);  aspect(pE, pDE)
                aspect(pAE, pA, alpha: 0.13); aspect(pBE, pB, alpha: 0.13)
                aspect(pCE, pC, alpha: 0.13); aspect(pDE, pD, alpha: 0.13)

                // ── Nodes ────────────────────────────────────────────────────
                let gold   = Color(hue: 0.12, saturation: 0.85, brightness: 0.92)
                let violet = Color(hue: 0.78, saturation: 0.70, brightness: 0.80)
                let blue   = Color(hue: 0.60, saturation: 0.70, brightness: 0.80)
                let teal   = Color(hue: 0.52, saturation: 0.60, brightness: 0.74)

                let nodes: [(CGPoint, Int, Color, CGFloat)] = [
                    (pA,  matrix.A,  gold,   18),
                    (pB,  matrix.B,  gold,   18),
                    (pC,  matrix.C,  gold,   18),
                    (pD,  matrix.D,  gold,   18),
                    (pE,  matrix.E,  violet, 23),
                    (pAB, matrix.AB, blue,   14),
                    (pBC, matrix.BC, blue,   14),
                    (pCD, matrix.CD, blue,   14),
                    (pDA, matrix.DA, blue,   14),
                    (pAE, matrix.AE, teal,   12),
                    (pBE, matrix.BE, teal,   12),
                    (pCE, matrix.CE, teal,   12),
                    (pDE, matrix.DE, teal,   12),
                ]

                for (pos, value, fill, r) in nodes {
                    // Soft glow ring
                    let glow = Path(ellipseIn: CGRect(x: pos.x-(r+4), y: pos.y-(r+4),
                                                      width: (r+4)*2, height: (r+4)*2))
                    context.fill(glow, with: .color(fill.opacity(0.20)))

                    // Filled circle
                    let circle = Path(ellipseIn: CGRect(x: pos.x-r, y: pos.y-r,
                                                        width: r*2, height: r*2))
                    context.fill(circle, with: .color(fill))
                    context.stroke(circle, with: .color(.white.opacity(0.50)), lineWidth: 1.2)

                    // Value label
                    context.draw(
                        Text(String(value))
                            .font(.system(size: r * 0.88, weight: .bold))
                            .foregroundColor(.white),
                        at: pos, anchor: .center
                    )
                }
            }
            .aspectRatio(1, contentMode: .fit)

            // Legend
            HStack(spacing: 14) {
                legendDot(Color(hue: 0.12, saturation: 0.85, brightness: 0.92), loc.t("legend_cardinal"))
                legendDot(Color(hue: 0.78, saturation: 0.70, brightness: 0.80), loc.t("legend_soul"))
                legendDot(Color(hue: 0.60, saturation: 0.70, brightness: 0.80), loc.t("legend_aspect"))
                legendDot(Color(hue: 0.52, saturation: 0.60, brightness: 0.74), loc.t("legend_path"))
            }
        }
        .padding()
        .background(Color.black.opacity(0.30))
        .cornerRadius(16)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption2).foregroundColor(.white.opacity(0.65))
        }
    }
}
