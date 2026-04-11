import SwiftUI

// MARK: - FORGE Design System

struct ForgeColor {
    // MARK: - Adaptive Backgrounds (respond to preferredColorScheme)
    static let background = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 6/255,  green: 6/255,  blue: 9/255,  alpha: 1)   // #060609
            : UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1) // iOS system grouped bg
    })
    static let surface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 14/255, green: 14/255, blue: 24/255, alpha: 1)   // #0E0E18
            : UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
    })
    static let surfaceElevated = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 20/255, green: 20/255, blue: 37/255, alpha: 1)   // #141425
            : UIColor.systemBackground
    })
    static let card = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 18/255, green: 18/255, blue: 30/255, alpha: 1)   // #12121E
            : UIColor.secondarySystemGroupedBackground
    })

    // Primary (unchanged — brand accent colors look good on both backgrounds)
    static let accent = Color(hex: "#7C3AED") ?? .purple
    static let accentBright = Color(hex: "#9D5FFF") ?? .purple
    static let accentGlow = Color(hex: "#7C3AED").map { $0.opacity(0.4) } ?? .purple.opacity(0.4)

    // State
    static let success = Color(hex: "#10B981") ?? .green
    static let successGlow = Color(hex: "#10B981").map { $0.opacity(0.3) } ?? .green.opacity(0.3)
    static let warning = Color(hex: "#F59E0B") ?? .yellow
    static let error = Color(hex: "#EF4444") ?? .red
    static let info = Color(hex: "#3B82F6") ?? .blue

    // MARK: - Adaptive Text Colors
    /// Primary text — white in dark mode, near-black in light mode.
    static let textPrimary = Color.primary
    /// Secondary text — adapts automatically to the current color scheme.
    static let textSecondary = Color.secondary
    /// Tertiary / hint text
    static let textTertiary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.35, alpha: 1)
            : UIColor(white: 0.50, alpha: 1)
    })

    // MARK: - Adaptive Borders
    static let border = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.12, alpha: 1)
            : UIColor(white: 0.80, alpha: 1)
    })
    static let borderSubtle = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.07, alpha: 1)
            : UIColor(white: 0.88, alpha: 1)
    })

    // Gradients
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#7C3AED") ?? .purple, Color(hex: "#4F46E5") ?? .indigo],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let fireGradient = LinearGradient(
        colors: [Color(hex: "#F97316") ?? .orange, Color(hex: "#EF4444") ?? .red],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let greenGradient = LinearGradient(
        colors: [Color(hex: "#10B981") ?? .green, Color(hex: "#059669") ?? .green],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(hex: "#F59E0B") ?? .yellow, Color(hex: "#D97706") ?? .orange],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func habitGradient(_ habit: Habit) -> LinearGradient {
        LinearGradient(
            colors: [habit.color, habit.color.opacity(0.6)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

struct ForgeTypography {
    // Display
    static let displayXL = Font.system(size: 56, weight: .black, design: .rounded)
    static let displayL = Font.system(size: 40, weight: .black, design: .rounded)
    static let displayM = Font.system(size: 32, weight: .bold, design: .rounded)

    // Headings
    static let h1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let h2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let h3 = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let h4 = Font.system(size: 15, weight: .semibold, design: .rounded)

    // Body
    static let bodyL = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyM = Font.system(size: 15, weight: .regular, design: .default)
    static let bodyS = Font.system(size: 13, weight: .regular, design: .default)

    // Labels
    static let labelM = Font.system(size: 13, weight: .medium, design: .rounded)
    static let labelS = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let labelXS = Font.system(size: 10, weight: .bold, design: .rounded)

    // Special
    static let mono = Font.system(size: 14, weight: .semibold, design: .monospaced)
    static let monoL = Font.system(size: 20, weight: .bold, design: .monospaced)
    static let scoreFont = Font.system(size: 48, weight: .black, design: .rounded)
}

struct ForgeSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct ForgeRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let full: CGFloat = 999
}

// MARK: - Custom View Modifiers

struct ForgeCardStyle: ViewModifier {
    var padding: CGFloat = ForgeSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: ForgeRadius.lg)
                    .stroke(ForgeColor.border, lineWidth: 1)
            )
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius)
    }
}

struct PressEffect: ViewModifier {
    // Intentionally a no-op. The previous DragGesture(minimumDistance: 0)
    // implementation hijacked scroll gestures inside lists and caused
    // habits to auto-tick while scrolling. SwiftUI's built-in Button press
    // highlight is sufficient; no custom gesture is needed.
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func forgeCard(padding: CGFloat = ForgeSpacing.md) -> some View {
        modifier(ForgeCardStyle(padding: padding))
    }

    func glowEffect(color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }

    func pressEffect() -> some View {
        modifier(PressEffect())
    }

    func forgeGradientText(_ gradient: LinearGradient) -> some View {
        self.overlay(gradient).mask(self)
    }
}

// MARK: - Animated Progress Ring
struct ForgeProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let gradient: LinearGradient
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(ForgeColor.border, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            if showGlow && progress > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth * 0.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 4)
                    .opacity(0.5)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Flame Badge
struct FlameBadge: View {
    let count: Int
    var size: CGFloat = 36

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(ForgeColor.fireGradient)
            Text("\(count)")
                .font(.system(size: size * 0.4, weight: .black, design: .rounded))
                .foregroundColor(ForgeColor.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.full)
                .fill(Color(hex: "#1A0A00") ?? .black)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeRadius.full)
                        .stroke(
                            LinearGradient(colors: [.orange.opacity(0.6), .red.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - XP Bar
struct XPBar: View {
    let progress: Double
    let level: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("LV.\(level)")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.accentBright)
                Spacer()
                Text("LV.\(level + 1)")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.textTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ForgeColor.border)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(ForgeColor.accentGradient)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Score Pill
struct ScorePill: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(ForgeColor.textPrimary)
            Text(label)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: ForgeRadius.md)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString

        guard hexString.count == 6,
              let hexValue = UInt64(hexString, radix: 16) else { return nil }

        let r = Double((hexValue >> 16) & 0xFF) / 255.0
        let g = Double((hexValue >> 8) & 0xFF) / 255.0
        let b = Double(hexValue & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    var hex: String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let r = Int((components[0]) * 255)
        let g = Int((components[1]) * 255)
        let b = Int((components[safe: 2] ?? 0) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Collection Extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Date Formatting
extension Date {
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: self)
    }

    var shortDateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }

    var dayName: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: self)
    }
}

// MARK: - Haptic Feedback
struct ForgeHaptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func heavy() {
        impact(.heavy)
    }

    static func light() {
        impact(.light)
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
                }
                .clipped()
            )
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
