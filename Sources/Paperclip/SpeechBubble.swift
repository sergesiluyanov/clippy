import SwiftUI

struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 1.0, green: 1.0, blue: 0.78)) // sticky-note yellow
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 1, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.4), lineWidth: 0.7)
                )

            // Little tail pointing down toward Clippy.
            Triangle()
                .fill(Color(red: 1.0, green: 1.0, blue: 0.78))
                .overlay(
                    Triangle().stroke(Color.black.opacity(0.4), lineWidth: 0.7)
                )
                .frame(width: 14, height: 8)
                .offset(y: -1)
        }
        .frame(maxWidth: 220)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
