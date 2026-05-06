import SwiftUI

/// Centreline of the Microsoft Office Clippit paperclip — one continuous bent
/// wire, exactly as it would be in real life.
///
/// When stroked with a thick line, the boundary of that stroke gives the two
/// concentric outlines you see in the reference: the outer silhouette of the
/// paperclip plus the inner outline that bounds the empty space inside the
/// head.  The wire is asymmetric on purpose:
///
///     start (▲) ── head ──╮
///                          │
///        ╭── head top ────╯
///        │
///        │           ▲ ← end (the bottom-right "tail")
///        │           │
///        │           │
///        ╰── bottom ─╯
///
struct ClippyShape: Shape {

    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width
            let h = rect.height

            // Four x rails the wire visits.
            // The wire is offset from the rect edges so the thick stroke
            // doesn't get clipped.
            let xOuterL: CGFloat = w * 0.12   // long left rail (top to bottom)
            let xInnerL: CGFloat = w * 0.34   // inner-left of the head
            let xInnerR: CGFloat = w * 0.55   // inner-right of the head (where the wire's TOP end sits)
            let xOuterR: CGFloat = w * 0.85   // short tail on the right

            // Y positions of key features.
            let yTop:        CGFloat = h * 0.07           // very top of the head's outer arc
            let yBot:        CGFloat = h * 0.93           // very bottom of the body
            let yHeadEnd:    CGFloat = h * 0.50           // bottom of the inner-head bend
            let yTailEndTop: CGFloat = h * 0.55           // top of the bottom-right tail (the wire's other end)

            // Big head arc — goes from the inner-left rail OVER the top to
            // the outer-LEFT rail.  Its centre is between those two rails.
            let headArcCX = (xOuterL + xInnerL) / 2
            let headArcR  = (xInnerL - xOuterL) / 2
            let headArcCY = yTop + headArcR

            // Small bend at the bottom of the inner head loop.
            let innerArcCX = (xInnerL + xInnerR) / 2
            let innerArcR  = (xInnerR - xInnerL) / 2
            let innerArcCY = yHeadEnd - innerArcR

            // Big bottom arc — goes from outer-LEFT to outer-RIGHT across
            // the full width of the body.
            let botArcCX = (xOuterL + xOuterR) / 2
            let botArcR  = (xOuterR - xOuterL) / 2
            let botArcCY = yBot - botArcR

            // === Trace the wire ===
            // 1) Wire's TOP end — visible "tip" sticking up inside the head.
            p.move(to: CGPoint(x: xInnerR, y: headArcCY - 2))

            // 2) Down the inner-right rail to the small bend at the bottom
            //    of the inner head loop.
            p.addLine(to: CGPoint(x: xInnerR, y: innerArcCY))

            // 3) Small U-bend across the bottom of the inner head
            //    (right -> left).
            p.addArc(
                center: CGPoint(x: innerArcCX, y: innerArcCY),
                radius: innerArcR,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false
            )

            // 4) Up the inner-left rail to the start of the head's top arc.
            p.addLine(to: CGPoint(x: xInnerL, y: headArcCY))

            // 5) BIG head arc — from inner-left up over the top down to
            //    outer-LEFT rail.
            p.addArc(
                center: CGPoint(x: headArcCX, y: headArcCY),
                radius: headArcR,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: true
            )

            // 6) Down the outer-LEFT rail — long, all the way to the
            //    bottom big bend.
            p.addLine(to: CGPoint(x: xOuterL, y: botArcCY))

            // 7) BIG bottom arc — from outer-LEFT across to outer-RIGHT.
            p.addArc(
                center: CGPoint(x: botArcCX, y: botArcCY),
                radius: botArcR,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )

            // 8) Up the outer-RIGHT rail — SHORT.  This is the wire's
            //    other free end, the bottom-right "tail tip".
            p.addLine(to: CGPoint(x: xOuterR, y: yTailEndTop))
        }
    }
}
