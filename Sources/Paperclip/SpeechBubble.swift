import SwiftUI

struct SpeechBubble: View {
    let text: String

    private let cornerRadius: CGFloat = 12
    private let tailWidth:    CGFloat = 14
    private let tailHeight:   CGFloat = 8
    private let bubbleFill   = Color(red: 1.00, green: 1.00, blue: 0.78)
    private let bubbleStroke = Color.black.opacity(0.40)

    var body: some View {
        let shape = BubbleShape(
            cornerRadius: cornerRadius,
            tailWidth:    tailWidth,
            tailHeight:   tailHeight
        )

        Text(text)
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            // Bottom padding leaves room for the tail that the
            // background shape draws.  The body padding (8) plus the
            // tail height keeps the text at the same visual position
            // inside the bubble as before.
            .padding(.bottom, 8 + tailHeight)
            .background(
                shape
                    .fill(bubbleFill)
                    .overlay(shape.stroke(bubbleStroke, lineWidth: 0.7))
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 1, y: 2)
            )
            .frame(maxWidth: 240)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Single closed path: rounded rectangle with a triangular tail
/// attached at the bottom centre.  Drawing it as one shape means
/// there are no seams, no doubled stroke at the join, and only one
/// drop shadow.
private struct BubbleShape: Shape {
    var cornerRadius: CGFloat
    var tailWidth:    CGFloat
    var tailHeight:   CGFloat

    func path(in rect: CGRect) -> Path {
        // The rounded-rect part of the bubble lives above the tail.
        let body = CGRect(
            x: rect.minX, y: rect.minY,
            width: rect.width,
            height: rect.height - tailHeight
        )
        let r = min(cornerRadius, min(body.width, body.height) / 2)
        let tailCx = body.midX
        let tailL  = tailCx - tailWidth / 2
        let tailR  = tailCx + tailWidth / 2
        let tipY   = rect.maxY
        let bottom = body.maxY

        return Path { p in
            // Top edge: start just after the top-left corner, go right.
            p.move(to: CGPoint(x: body.minX + r, y: body.minY))
            p.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))

            // Top-right corner.
            p.addArc(
                center: CGPoint(x: body.maxX - r, y: body.minY + r),
                radius: r,
                startAngle: .degrees(-90),
                endAngle:   .degrees(0),
                clockwise: false
            )

            // Right edge.
            p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))

            // Bottom-right corner.
            p.addArc(
                center: CGPoint(x: body.maxX - r, y: body.maxY - r),
                radius: r,
                startAngle: .degrees(0),
                endAngle:   .degrees(90),
                clockwise: false
            )

            // Bottom edge → right side of the tail.
            p.addLine(to: CGPoint(x: tailR, y: bottom))

            // Down to the tail tip and back up to the left side of the tail.
            p.addLine(to: CGPoint(x: tailCx, y: tipY))
            p.addLine(to: CGPoint(x: tailL, y: bottom))

            // Bottom edge → bottom-left corner.
            p.addLine(to: CGPoint(x: body.minX + r, y: bottom))

            // Bottom-left corner.
            p.addArc(
                center: CGPoint(x: body.minX + r, y: body.maxY - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle:   .degrees(180),
                clockwise: false
            )

            // Left edge.
            p.addLine(to: CGPoint(x: body.minX, y: body.minY + r))

            // Top-left corner — closes the loop.
            p.addArc(
                center: CGPoint(x: body.minX + r, y: body.minY + r),
                radius: r,
                startAngle: .degrees(180),
                endAngle:   .degrees(270),
                clockwise: false
            )

            p.closeSubpath()
        }
    }
}
