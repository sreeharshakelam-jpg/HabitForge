import Foundation
import SwiftUI

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let requirement: AchievementRequirement
    let xpReward: Int
    let pointsReward: Int
    var unlockedAt: Date?
    var progress: Double

    var isUnlocked: Bool { unlockedAt != nil }

    var color: Color {
        rarity.color
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "streak"
    case completion = "completion"
    case consistency = "consistency"
    case milestone = "milestone"
    case social = "social"
    case special = "special"
    case discipline = "discipline"

    var displayName: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .completion: return "checkmark.seal.fill"
        case .consistency: return "chart.bar.fill"
        case .milestone: return "flag.fill"
        case .social: return "person.2.fill"
        case .special: return "star.fill"
        case .discipline: return "bolt.fill"
        }
    }
}

enum AchievementRarity: String, Codable, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case mythic = "mythic"

    var displayName: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .common: return Color(hex: "#9CA3AF") ?? .gray
        case .rare: return Color(hex: "#3B82F6") ?? .blue
        case .epic: return Color(hex: "#8B5CF6") ?? .purple
        case .legendary: return Color(hex: "#F59E0B") ?? .yellow
        case .mythic: return Color(hex: "#EF4444") ?? .red
        }
    }

    var glowColor: Color {
        color.opacity(0.6)
    }
}

enum AchievementRequirement: Codable {
    case streakDays(Int)
    case totalCompletions(Int)
    case perfectDays(Int)
    case totalPoints(Int)
    case totalXP(Int)
    case level(Int)
    case habitsCreated(Int)
    case comebackAfterMiss
    case earlyBird(Int)         // Complete habits early X times
    case nightOwl(Int)
    case custom(String)
}

// MARK: - Achievement Library
struct AchievementLibrary {
    static let all: [Achievement] = [
        // STREAK ACHIEVEMENTS
        Achievement(
            id: "streak_3", title: "Ignition", description: "Complete habits 3 days in a row",
            icon: "🔥", category: .streak, rarity: .common,
            requirement: .streakDays(3), xpReward: 50, pointsReward: 100, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "streak_7", title: "One Week Warrior", description: "7-day streak. You're building momentum!",
            icon: "⚡", category: .streak, rarity: .rare,
            requirement: .streakDays(7), xpReward: 150, pointsReward: 300, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "streak_14", title: "Fortnight Forge", description: "14 days of pure discipline",
            icon: "🔱", category: .streak, rarity: .rare,
            requirement: .streakDays(14), xpReward: 300, pointsReward: 600, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "streak_21", title: "Habit Formed", description: "21 days — science says you've built a habit",
            icon: "🧬", category: .streak, rarity: .epic,
            requirement: .streakDays(21), xpReward: 500, pointsReward: 1000, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "streak_30", title: "Iron Month", description: "30-day streak. You are unstoppable",
            icon: "⚔️", category: .streak, rarity: .epic,
            requirement: .streakDays(30), xpReward: 750, pointsReward: 1500, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "streak_60", title: "Diamond Discipline", description: "60 days of consistent excellence",
            icon: "💎", category: .streak, rarity: .legendary,
            requirement: .streakDays(60), xpReward: 1500, pointsReward: 3000, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "streak_100", title: "The Century", description: "100 days. Legends are made of this",
            icon: "👑", category: .streak, rarity: .legendary,
            requirement: .streakDays(100), xpReward: 2500, pointsReward: 5000, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "streak_365", title: "Year of the Sage", description: "365 days. You have transcended",
            icon: "🌟", category: .streak, rarity: .mythic,
            requirement: .streakDays(365), xpReward: 10000, pointsReward: 20000, unlockedAt: nil, progress: 0
        ),

        // COMPLETION ACHIEVEMENTS
        Achievement(
            id: "complete_10", title: "First Steps", description: "Complete 10 habits total",
            icon: "👣", category: .completion, rarity: .common,
            requirement: .totalCompletions(10), xpReward: 25, pointsReward: 50, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "complete_100", title: "Centurion", description: "100 total habit completions",
            icon: "💯", category: .completion, rarity: .rare,
            requirement: .totalCompletions(100), xpReward: 200, pointsReward: 400, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "complete_1000", title: "Thousand Forge", description: "1000 habits completed. Extraordinary.",
            icon: "🏆", category: .completion, rarity: .epic,
            requirement: .totalCompletions(1000), xpReward: 1000, pointsReward: 2000, unlockedAt: nil, progress: 0
        ),

        // PERFECT DAY ACHIEVEMENTS
        Achievement(
            id: "perfect_1", title: "Perfect Day", description: "Complete every habit in a single day",
            icon: "✨", category: .consistency, rarity: .common,
            requirement: .perfectDays(1), xpReward: 100, pointsReward: 200, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "perfect_7", title: "Perfect Week", description: "7 perfect days — flawless execution",
            icon: "🎯", category: .consistency, rarity: .legendary,
            requirement: .perfectDays(7), xpReward: 1000, pointsReward: 2000, unlockedAt: nil, progress: 0
        ),

        // COMEBACK ACHIEVEMENT
        Achievement(
            id: "comeback", title: "Phoenix Rising", description: "Return after missing 3+ days and complete all habits",
            icon: "🦅", category: .special, rarity: .epic,
            requirement: .comebackAfterMiss, xpReward: 500, pointsReward: 1000, unlockedAt: nil, progress: 0
        ),

        // LEVEL ACHIEVEMENTS
        Achievement(
            id: "level_10", title: "Level 10 Forger", description: "Reach Level 10",
            icon: "⬆️", category: .milestone, rarity: .rare,
            requirement: .level(10), xpReward: 300, pointsReward: 600, unlockedAt: nil, progress: 0
        ),
        Achievement(
            id: "level_50", title: "Master Forger", description: "Reach Level 50",
            icon: "🎖️", category: .milestone, rarity: .epic,
            requirement: .level(50), xpReward: 1500, pointsReward: 3000, unlockedAt: nil, progress: 0
        ),

        // EARLY BIRD
        Achievement(
            id: "early_bird_7", title: "Early Bird", description: "Complete morning habits early, 7 times",
            icon: "🌅", category: .discipline, rarity: .rare,
            requirement: .earlyBird(7), xpReward: 200, pointsReward: 400, unlockedAt: nil, progress: 0
        ),
    ]

    static func achievement(byId id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}

// MARK: - Daily Report
struct DailyReport: Identifiable, Codable {
    let id: UUID
    let date: Date
    var totalHabits: Int
    var completedHabits: Int
    var missedHabits: Int
    var skippedHabits: Int
    var pointsEarned: Int
    var xpEarned: Int
    var isPerfectDay: Bool
    var streakAtEndOfDay: Int
    var disciplineScoreChange: Int
    var motivationalMessage: String
    var reflectionQuestion: String
    var achievements: [String]  // Achievement IDs unlocked this day

    var completionRate: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedHabits) / Double(totalHabits)
    }

    var grade: DayGrade {
        switch completionRate {
        case 1.0: return .perfect
        case 0.8...: return .excellent
        case 0.6...: return .good
        case 0.4...: return .okay
        default: return .poor
        }
    }
}

enum DayGrade: String, Codable {
    case perfect = "perfect"
    case excellent = "excellent"
    case good = "good"
    case okay = "okay"
    case poor = "poor"

    var displayName: String { rawValue.capitalized }

    var emoji: String {
        switch self {
        case .perfect: return "🔥"
        case .excellent: return "⭐"
        case .good: return "✅"
        case .okay: return "👍"
        case .poor: return "💪"
        }
    }

    var color: Color {
        switch self {
        case .perfect: return Color(hex: "#10B981") ?? .green
        case .excellent: return Color(hex: "#22C55E") ?? .green
        case .good: return Color(hex: "#3B82F6") ?? .blue
        case .okay: return Color(hex: "#F59E0B") ?? .yellow
        case .poor: return Color(hex: "#EF4444") ?? .red
        }
    }

    var message: String {
        switch self {
        case .perfect: return "PERFECT DAY! You are unstoppable. 🔥"
        case .excellent: return "Excellent work. You're building something great. ⭐"
        case .good: return "Good day. Keep the momentum going. ✅"
        case .okay: return "Decent. Tomorrow push harder. 💪"
        case .poor: return "Rough day. Rise tomorrow. You've got this. 🦅"
        }
    }
}
