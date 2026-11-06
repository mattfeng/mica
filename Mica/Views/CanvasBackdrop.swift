import SwiftUI

enum MicaPalette {
    static func window(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.087, green: 0.091, blue: 0.094)
            : Color(red: 0.966, green: 0.962, blue: 0.952)
    }

    static func line(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.10) : .black.opacity(0.075)
    }

    static func muted(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.68, green: 0.69, blue: 0.68)
            : Color(red: 0.38, green: 0.40, blue: 0.38)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.165, green: 0.17, blue: 0.177)
            : Color.white
    }
}

struct CanvasBackdrop: View {
    let scheme: ColorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                (scheme == .dark
                    ? Color(red: 0.125, green: 0.132, blue: 0.135)
                    : Color(red: 0.985, green: 0.981, blue: 0.973))
                Canvas { context, size in
                    var dots = Path()
                    let spacing: CGFloat = 26
                    for x in stride(from: CGFloat(15), through: size.width, by: spacing) {
                        for y in stride(from: CGFloat(15), through: size.height, by: spacing) {
                            dots.addEllipse(in: CGRect(x: x, y: y, width: 1.3, height: 1.3))
                        }
                    }
                    context.fill(dots, with: .color(scheme == .dark
                        ? .white.opacity(0.14) : .black.opacity(0.15)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipped()
    }
}
