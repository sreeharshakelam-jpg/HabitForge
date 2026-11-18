import SwiftUI

// MARK: - Aurora Background
// Slowly drifting glow blobs tinted by the active theme, behind every main tab.

struct ForgeAuroraBackground: View {
    @State private var drift = false

    var body: some View {
        let t = ForgeThemeManager.current
        ZStack {
            ForgeColor.background
            Circle()
                .fill(Color(hex: t.gradientStartHex) ?? .purple)
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .opacity(0.35)
                .offset(x: drift ? -120 : -60, y: drift ? -330 : -260)
            Circle()
                .fill(Color(hex: t.gradientEndHex) ?? .indigo)
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .opacity(0.3)
                .offset(x: drift ? 140 : 90, y: drift ? -200 : -290)
            Circle()
                .fill(t.accentBright)
                .frame(width: 260, height: 260)
                .blur(radius: 100)
                .opacity(0.18)
                .offset(x: drift ? 50 : -50, y: drift ? 330 : 260)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

// MARK: - Habit Celebration
// Full-screen burst when a habit is ticked: the avatar jumps in flexing,
// confetti flies out, and a hype line pops. Never blocks touches.

struct HabitCelebrationOverlay: View {
    let gender: AvatarGender
    let muscle: Double
    let message: String

    private struct Piece {
        let x: CGFloat, y: CGFloat, spin: Double, color: Color, w: CGFloat
    }

    @State private var burst = false
    @State private var pieces: [Piece] = (0..<36).map { _ in
        Piece(
            x: .random(in: -190...190),
            y: .random(in: -420...160),
            spin: .random(in: -540...540),
            color: [Color.yellow, .pink, .orange, .green, .cyan, .purple, .red].randomElement()!,
            w: .random(in: 6...11)
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(burst ? 0.35 : 0).ignoresSafeArea()

            ForEach(pieces.indices, id: \.self) { i in
                let p = pieces[i]
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.w, height: p.w * 1.8)
                    .rotationEffect(.degrees(burst ? p.spin : 0))
                    .offset(x: burst ? p.x : 0, y: burst ? p.y : 0)
                    .opacity(burst ? 0 : 1)
                    .animation(.easeOut(duration: 1.5), value: burst)
            }

            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [ForgeColor.accent.opacity(0.6), .clear],
                                             center: .center, startRadius: 10, endRadius: 140))
                        .frame(width: 280, height: 280)
                        .scaleEffect(burst ? 1.1 : 0.6)
                    AnimeAvatarView(gender: gender, muscle: muscle, flexing: true)
                        .frame(width: 180, height: 250)
                        .offset(y: burst ? -16 : 60)
                }
                Text(message)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(ForgeColor.accentGradient)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(.white))
                    .shadow(color: ForgeColor.accent.opacity(0.5), radius: 12)
                    .scaleEffect(burst ? 1 : 0.3)
            }
            .scaleEffect(burst ? 1 : 0.5)
            .opacity(burst ? 1 : 0)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { burst = true }
        }
    }

    static func randomMessage(perfectDay: Bool) -> String {
        if perfectDay { return "PERFECT DAY! 👑" }
        return ["YES! 🔥", "LET'S GO! 💪", "+1 REP FORGED!", "UNSTOPPABLE! ⚡️", "THAT'S YOU! 🌟"].randomElement()!
    }
}
