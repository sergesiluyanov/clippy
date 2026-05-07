import SwiftUI

/// Clippit reborn, in the style of the Microsoft Office 97/98 assistant:
/// a tall lavender paperclip with a dark outlined wire, with two big googly
/// eyes perched on top of the head and short chunky black eyebrows above them.
struct ClippyView: View {

    @ObservedObject var viewModel: ClippyViewModel
    let onClick: () -> Void

    @State private var blinkClosed = false
    @State private var wiggle = false
    @State private var bobUp = false
    @State private var gazeOffset = CGSize(width: 1.5, height: 0)

    // Master sizing.
    private let bodyW: CGFloat = 130
    private let bodyH: CGFloat = 175

    // Colours of the wire.
    private let wireFill   = Color(red: 0.74, green: 0.71, blue: 0.85)
    private let wireStroke = Color(red: 0.32, green: 0.28, blue: 0.43)

    var body: some View {
        // GeometryReader gives us the actual window/host size so we can
        // anchor Clippy to the bottom and let the bubble grow UP into the
        // free space, without ever asking NSHostingView for more height
        // than the window has.
        GeometryReader { geo in
            VStack(spacing: 4) {
                Spacer(minLength: 0)

                // Speech bubble — height is fully driven by content.
                ZStack {
                    if let text = viewModel.quip {
                        SpeechBubble(text: text)
                            .transition(.scale(scale: 0.7, anchor: .bottom)
                                .combined(with: .opacity))
                            .padding(.horizontal, 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                // Animate both the appearing/disappearing and the size
                // change when the quip itself is swapped for a longer or
                // shorter line.
                .animation(.spring(response: 0.38, dampingFraction: 0.78),
                           value: viewModel.quip)

                // The character.  Paper has been removed for now — we'll
                // bring it back once the silhouette is right.
                ZStack(alignment: .center) {
                    clippyBody
                        .frame(width: bodyW, height: bodyH)

                    // Eyes nestled in the head loop, dead-centre horizontally.
                    ClippyFace(
                        blinkClosed: blinkClosed,
                        mood: viewModel.mood,
                        gazeOffset: gazeOffset
                    )
                    .offset(x: 0, y: -bodyH * 0.30)
                }
                // A barely-there idle wiggle.
                .rotationEffect(.degrees(wiggle ? 2.5 : -2.5), anchor: .bottom)
                .offset(y: bobUp ? -1.5 : 1.5)
                .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: wiggle)
                .animation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true), value: bobUp)
                .contentShape(Rectangle())
                .onTapGesture { onClick() }
            }
            .padding(8)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
        .onAppear {
            wiggle = true
            bobUp = true
            scheduleBlink()
            scheduleGazeShift()
        }
    }

    // MARK: - Body (the paperclip wire itself)

    private var clippyBody: some View {
        // The same SF Symbol used in the menu bar — a real paperclip
        // silhouette.  The system symbol is drawn at a 35° tilt, so
        // we counter-rotate it to make Clippy stand upright.
        // A light symbol weight gives the thin wire we want.
        Image(systemName: "paperclip")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .font(.system(size: 1, weight: .light))
            .foregroundStyle(wireFill)
            .rotationEffect(.degrees(-32))
    }

    // MARK: - Lined paper Clippy is standing on

    /// A tilted yellow notebook sheet with ruled lines, a red margin and
    /// a curled top-right corner.  The whole shape is a quadrilateral so
    /// the left-to-right perspective is a property of the geometry, not
    /// a 3D rotation.
    private struct LinedPaper: View {
        // Helpers
        private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }

        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // Four corners of the tilted sheet.  The bottom-left
                // corner is the closest (lowest) point to the viewer;
                // the top-right corner sits highest and is the one that
                // gets curled.  These ratios shape the perspective.
                let TL = CGPoint(x: w * 0.14, y: h * 0.42)
                let TR = CGPoint(x: w * 0.84, y: h * 0.06)
                let BR = CGPoint(x: w * 0.97, y: h * 0.58)
                let BL = CGPoint(x: w * 0.03, y: h * 0.94)

                // Where the curl crease meets the top and right edges
                let curlT = Self.lerp(TL, TR, 0.78)   // crease on top edge
                let curlR = Self.lerp(TR, BR, 0.22)   // crease on right edge
                // Folded-back tip (mirror of TR around the crease line)
                let creaseMid = Self.lerp(curlT, curlR, 0.5)
                let curledTip = CGPoint(x: 2 * creaseMid.x - TR.x,
                                        y: 2 * creaseMid.y - TR.y)

                // Main sheet (with the corner cut off where the curl is)
                let sheetPath = Path { p in
                    p.move(to: TL)
                    p.addLine(to: curlT)
                    p.addLine(to: curlR)
                    p.addLine(to: BR)
                    p.addLine(to: BL)
                    p.closeSubpath()
                }
                // Folded-over corner triangle
                let foldPath = Path { p in
                    p.move(to: curlT)
                    p.addLine(to: curledTip)
                    p.addLine(to: curlR)
                    p.closeSubpath()
                }

                ZStack {
                    // Paper fill
                    sheetPath
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.97, blue: 0.74),
                                    Color(red: 0.95, green: 0.88, blue: 0.50)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Red margin line near the left edge of the sheet
                    Path { p in
                        let start = Self.lerp(TL, TR, 0.10)
                        let end   = Self.lerp(BL, BR, 0.10)
                        p.move(to: start)
                        p.addLine(to: end)
                    }
                    .stroke(Color(red: 0.78, green: 0.18, blue: 0.18).opacity(0.55),
                            lineWidth: 1)
                    .mask(sheetPath)

                    // Faint horizontal ruling lines, parallel to the
                    // top/bottom edges of the paper.
                    Path { p in
                        let lines = 7
                        for i in 1...lines {
                            let t = CGFloat(i) / CGFloat(lines + 1)
                            let a = Self.lerp(TL, BL, t)
                            let b = Self.lerp(TR, BR, t)
                            p.move(to: a)
                            p.addLine(to: b)
                        }
                    }
                    .stroke(Color(red: 0.30, green: 0.50, blue: 0.85).opacity(0.45),
                            lineWidth: 0.7)
                    .mask(sheetPath)

                    // Outline of the sheet
                    sheetPath
                        .stroke(Color(red: 0.55, green: 0.45, blue: 0.20), lineWidth: 0.9)

                    // Folded-back corner — the underside of the paper
                    // is a slightly paler / more white tone.
                    foldPath
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.99, blue: 0.94),
                                    Color(red: 0.96, green: 0.93, blue: 0.78)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    foldPath
                        .stroke(Color(red: 0.55, green: 0.45, blue: 0.20), lineWidth: 0.9)

                    // Soft shading along the crease so the fold reads as 3D
                    Path { p in
                        p.move(to: curlT)
                        p.addLine(to: curlR)
                    }
                    .stroke(Color.black.opacity(0.18), lineWidth: 1.4)
                    .blur(radius: 0.8)
                }
            }
        }
    }

    /// Long oblique smudge cast by Clippy onto the paper, behind and to
    /// the right of him (matching the paper's left-to-right perspective).
    private struct ClippyCastShadow: View {
        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                Path { p in
                    // A skinny diamond-ish blob laid down behind Clippy
                    p.move(to:    CGPoint(x: w * 0.05, y: h * 0.85))
                    p.addQuadCurve(
                        to:       CGPoint(x: w * 0.95, y: h * 0.30),
                        control:  CGPoint(x: w * 0.55, y: h * 0.20))
                    p.addQuadCurve(
                        to:       CGPoint(x: w * 0.05, y: h * 0.85),
                        control:  CGPoint(x: w * 0.45, y: h * 1.00))
                    p.closeSubpath()
                }
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.10)
                        ],
                        center: UnitPoint(x: 0.30, y: 0.65),
                        startRadius: 4,
                        endRadius: max(w, h) * 0.55
                    )
                )
            }
        }
    }

    // MARK: - Idle animations

    private func scheduleBlink() {
        let delay = Double.random(in: 2.4...5.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.07)) { blinkClosed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.easeInOut(duration: 0.10)) { blinkClosed = false }
                scheduleBlink()
            }
        }
    }

    private func scheduleGazeShift() {
        let delay = Double.random(in: 3.0...7.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let candidates: [CGSize] = [
                CGSize(width:  1.8, height:  0.0),
                CGSize(width:  2.3, height:  0.5),
                CGSize(width: -1.5, height:  0.0),
                CGSize(width:  0.0, height: -1.0),
                CGSize(width:  2.0, height:  1.0)
            ]
            withAnimation(.easeInOut(duration: 0.35)) {
                gazeOffset = candidates.randomElement() ?? .zero
            }
            scheduleGazeShift()
        }
    }
}

enum ClippyMood {
    case neutral, sassy, smug, worried
}

// MARK: - Face (eyes + eyebrows)

private struct ClippyFace: View {
    let blinkClosed: Bool
    let mood: ClippyMood
    let gazeOffset: CGSize

    private let eyeSize: CGFloat = 24

    var body: some View {
        ZStack {
            // Two short, chunky eyebrow dashes just above each eye.
            HStack(spacing: 8) {
                Eyebrow(tilt: leftBrowTilt)
                Eyebrow(tilt: rightBrowTilt)
            }
            .offset(y: -eyeSize * 0.78)

            // The two googly eyes — right one slightly larger and a touch
            // higher, like the original Clippy.
            HStack(alignment: .bottom, spacing: 2) {
                ClippyEye(size: eyeSize, closed: blinkClosed, gaze: gazeOffset)
                    .offset(y: 1)
                ClippyEye(size: eyeSize * 1.08, closed: blinkClosed, gaze: gazeOffset)
                    .offset(y: -1.5)
            }
        }
    }

    private var leftBrowTilt: Double {
        switch mood {
        case .neutral: return  -8
        case .sassy:   return -18
        case .smug:    return  14
        case .worried: return -28
        }
    }
    private var rightBrowTilt: Double {
        switch mood {
        case .neutral: return   8
        case .sassy:   return  -2
        case .smug:    return -14
        case .worried: return  28
        }
    }
}

// MARK: - One googly eye

private struct ClippyEye: View {
    let size: CGFloat
    let closed: Bool
    let gaze: CGSize

    var body: some View {
        ZStack {
            // Sclera — slightly off-white with a soft shaded edge for depth.
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color(white: 0.86)],
                        center: UnitPoint(x: 0.32, y: 0.30),
                        startRadius: 1,
                        endRadius: size
                    )
                )
                .overlay(
                    Ellipse().strokeBorder(Color.black, lineWidth: 1.7)
                )
                .frame(width: size, height: size * 1.08)

            if closed {
                EyeLid()
                    .stroke(Color.black, style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
                    .frame(width: size * 0.78, height: 6)
            } else {
                // Big black pupil with a tiny white catch-light reflection.
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: size * 0.55, height: size * 0.55)
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.20, height: size * 0.20)
                        .offset(x: -size * 0.10, y: -size * 0.13)
                }
                .offset(x: gaze.width, y: gaze.height)
            }
        }
    }
}

private struct EyeLid: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.midY),
                control: CGPoint(x: rect.midX, y: rect.maxY)
            )
        }
    }
}

// MARK: - Eyebrow (short chunky dash)

private struct Eyebrow: View {
    let tilt: Double

    var body: some View {
        Capsule()
            .fill(Color.black)
            .frame(width: 16, height: 4)
            .rotationEffect(.degrees(tilt))
    }
}
