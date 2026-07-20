import SwiftUI
import UIKit

// MARK: - Forge Theme
// A complete visual identity: accent colors, gradients, and tinted dark
// backgrounds. Selected theme persists in UserDefaults and drives every
// ForgeColor token app-wide.

struct ForgeTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let tagline: String
    let emoji: String

    // Accent system
    let accentHex: String
    let accentBrightHex: String
    let gradientStartHex: String
    let gradientEndHex: String

    // Dark-mode tinted backgrounds (light mode stays system standard)
    let darkBackgroundHex: String
    let darkSurfaceHex: String
    let darkSurfaceElevatedHex: String
    let darkCardHex: String

    var accent: Color { Color(hex: accentHex) ?? .purple }
    var accentBright: Color { Color(hex: accentBrightHex) ?? .purple }
    var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: gradientStartHex) ?? .purple, Color(hex: gradientEndHex) ?? .indigo],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    var previewGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: gradientStartHex) ?? .purple,
                     Color(hex: accentBrightHex) ?? .purple,
                     Color(hex: gradientEndHex) ?? .indigo],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Theme Library

extension ForgeTheme {
    static let royalForge = ForgeTheme(
        id: "royal", name: "Royal Forge", tagline: "The classic. Regal purple power.", emoji: "👑",
        accentHex: "#7C3AED", accentBrightHex: "#9D5FFF",
        gradientStartHex: "#7C3AED", gradientEndHex: "#4F46E5",
        darkBackgroundHex: "#060609", darkSurfaceHex: "#0E0E18",
        darkSurfaceElevatedHex: "#141425", darkCardHex: "#12121E"
    )

    static let emberForge = ForgeTheme(
        id: "ember", name: "Ember Forge", tagline: "Molten fire. Relentless drive.", emoji: "🔥",
        accentHex: "#F1500B", accentBrightHex: "#FF7A3D",
        gradientStartHex: "#F1500B", gradientEndHex: "#C81E1E",
        darkBackgroundHex: "#0A0503", darkSurfaceHex: "#160B06",
        darkSurfaceElevatedHex: "#211008", darkCardHex: "#1B0D07"
    )

    static let aurora = ForgeTheme(
        id: "aurora", name: "Aurora", tagline: "Northern lights. Calm mastery.", emoji: "🌌",
        accentHex: "#10C989", accentBrightHex: "#3DF0B0",
        gradientStartHex: "#10C989", gradientEndHex: "#0891B2",
        darkBackgroundHex: "#03080A", darkSurfaceHex: "#071410",
        darkSurfaceElevatedHex: "#0A1F18", darkCardHex: "#081A14"
    )

    static let midnightGold = ForgeTheme(
        id: "gold", name: "Midnight Gold", tagline: "Black tie. Champagne victories.", emoji: "🏆",
        accentHex: "#D4A12A", accentBrightHex: "#F2CC5B",
        gradientStartHex: "#D4A12A", gradientEndHex: "#8A6410",
        darkBackgroundHex: "#080704", darkSurfaceHex: "#12100A",
        darkSurfaceElevatedHex: "#1C180E", darkCardHex: "#17140C"
    )

    static let neonPulse = ForgeTheme(
        id: "neon", name: "Neon Pulse", tagline: "Electric nights. Cyber energy.", emoji: "⚡",
        accentHex: "#EC1E7B", accentBrightHex: "#FF5EA8",
        gradientStartHex: "#EC1E7B", gradientEndHex: "#7B2FF7",
        darkBackgroundHex: "#0A0410", darkSurfaceHex: "#150822",
        darkSurfaceElevatedHex: "#1F0C31", darkCardHex: "#1A0A29"
    )

    static let oceanDepth = ForgeTheme(
        id: "ocean", name: "Ocean Depth", tagline: "Deep focus. Steady tide.", emoji: "🌊",
        accentHex: "#0EA5E9", accentBrightHex: "#4CC9FF",
        gradientStartHex: "#0EA5E9", gradientEndHex: "#1E40AF",
        darkBackgroundHex: "#03060C", darkSurfaceHex: "#071120",
        darkSurfaceElevatedHex: "#0A1930", darkCardHex: "#081527"
    )

    static let all: [ForgeTheme] = [.royalForge, .emberForge, .aurora, .midnightGold, .neonPulse, .oceanDepth]
}

// MARK: - Theme Manager

enum ForgeThemeManager {
    static let storageKey = "forgeThemeId"

    static var current: ForgeTheme {
        let id = UserDefaults.standard.string(forKey: storageKey) ?? "royal"
        return ForgeTheme.all.first { $0.id == id } ?? .royalForge
    }

    static func select(_ theme: ForgeTheme) {
        UserDefaults.standard.set(theme.id, forKey: storageKey)
    }
}

// MARK: - UIColor Hex Helper (for adaptive dark backgrounds)

extension UIColor {
    convenience init(forgeHex hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
