import Foundation
import SwiftUI

// MARK: - User Profile
struct UserProfile: Codable {
    var id: UUID
    var name: String
    var username: String
    var avatarEmoji: String
    var bio: String
    var goals: [UserGoal]
    var createdAt: Date
    var timezone: String
    var wakeUpTime: Date
    var sleepTime: Date
    var isPremium: Bool
    var premiumExpiry: Date?
    var preferredTheme: AppTheme

    // Gamification
    var level: Int
    var totalXP: Int
    var totalPoints: Int
    var disciplineScore: Int
    var consistencyScore: Int
    var rank: UserRank
    var currentStreak: Int
    var longestStreak: Int
    var totalHabitsCompleted: Int
    var perfectDays: Int
    var comebackCount: Int

    // Preferences
    var notificationsEnabled: Bool
    var motivationalQuotes: Bool
    var dailyCheckInEnabled: Bool
    var weeklyReportEnabled: Bool
    var soundEnabled: Bool
    var hapticEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        username: String = "",
        avatarEmoji: String = "🔥",
        bio: String = "",
        goals: [UserGoal] = [],
        createdAt: Date = Date(),
        timezone: String = TimeZone.current.identifier,
        wakeUpTime: Date = Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
        sleepTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(),
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.avatarEmoji = avatarEmoji
        self.bio = bio
        self.goals = goals
        self.createdAt = createdAt
        self.timezone = timezone
        self.wakeUpTime = wakeUpTime
        self.sleepTime = sleepTime
        self.isPremium = isPremium
        self.preferredTheme = .darkForge

        // Initialize gamification
        self.level = 1
        self.totalXP = 0
        self.totalPoints = 0
        self.disciplineScore = 100
        self.consistencyScore = 0
        self.rank = .novice
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalHabitsCompleted = 0
        self.perfectDays = 0
        self.comebackCount = 0

        // Default preferences
        self.notificationsEnabled = true
        self.motivationalQuotes = true
        self.dailyCheckInEnabled = true
        self.weeklyReportEnabled = true
        self.soundEnabled = true
        self.hapticEnabled = true
    }

    var xpForCurrentLevel: Int {
        UserRank.xpRequired(forLevel: level)
    }

    var xpForNextLevel: Int {
        UserRank.xpRequired(forLevel: level + 1)
    }

    var levelProgress: Double {
        let current = totalXP - xpForCurrentLevel
        let needed = xpForNextLevel - xpForCurrentLevel
        guard needed > 0 else { return 1.0 }
        return min(Double(current) / Double(needed), 1.0)
    }
}

// MARK: - User Goal
enum UserGoal: String, Codable, CaseIterable {
    case fitness = "fitness"
    case focus = "focus"
    case study = "study"
    case sleep = "sleep"
    case deepWork = "deepWork"
    case mentalWellness = "mentalWellness"
    case nutrition = "nutrition"
    case creativity = "creativity"
    case finance = "finance"
    case relationships = "relationships"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .fitness: return "Get Fit"
        case .focus: return "Deep Focus"
        case .study: return "Study & Learn"
        case .sleep: return "Better Sleep"
        case .deepWork: return "Deep Work"
        case .mentalWellness: return "Mental Health"
        case .nutrition: return "Eat Better"
        case .creativity: return "Create More"
        case .finance: return "Build Wealth"
        case .relationships: return "Nurture Bonds"
        case .custom: return "My Own Path"
        }
    }

    var description: String {
        switch self {
        case .fitness: return "Build a strong, healthy body"
        case .focus: return "Eliminate distraction, master attention"
        case .study: return "Learn faster and retain more"
        case .sleep: return "Optimize rest and recovery"
        case .deepWork: return "Do meaningful, high-output work"
        case .mentalWellness: return "Calm the mind, build resilience"
        case .nutrition: return "Fuel your body for peak performance"
        case .creativity: return "Unlock creative output daily"
        case .finance: return "Build smart money habits"
        case .relationships: return "Invest in the people that matter"
        case .custom: return "Define your own transformation"
        }
    }

    var icon: String {
        switch self {
        case .fitness: return "🏋️"
        case .focus: return "🎯"
        case .study: return "📚"
        case .sleep: return "🌙"
        case .deepWork: return "⚡"
        case .mentalWellness: return "🧠"
        case .nutrition: return "🥗"
        case .creativity: return "🎨"
        case .finance: return "💎"
        case .relationships: return "❤️"
        case .custom: return "🔥"
        }
    }

    var suggestedHabits: [Habit] {
        switch self {
        case .fitness:
            return [
                Habit(name: "Morning Workout", icon: "dumbbell.fill", colorHex: "#EF4444",
                      category: .fitness, type: .timeBased,
                      scheduledTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)),
                      difficulty: .hard),
                Habit(name: "10,000 Steps", icon: "figure.walk", colorHex: "#F97316",
                      category: .fitness, type: .quantity, difficulty: .medium,
                      targetValue: 10000, targetUnit: "steps"),
                Habit(name: "Stretch / Mobility", icon: "figure.flexibility", colorHex: "#8B5CF6",
                      category: .fitness, type: .duration,
                      durationMinutes: 10, difficulty: .easy)
            ]
        case .sleep:
            return [
                Habit(name: "Sleep by 10:30 PM", icon: "moon.stars.fill", colorHex: "#6366F1",
                      category: .sleep, type: .timeBased,
                      scheduledTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)),
                      difficulty: .hard),
                Habit(name: "No Screens 1hr Before Bed", icon: "iphone.slash", colorHex: "#8B5CF6",
                      category: .sleep, type: .avoidance, difficulty: .medium),
                Habit(name: "Wake Up at 5:30 AM", icon: "sunrise.fill", colorHex: "#F59E0B",
                      category: .sleep, type: .timeBased,
                      scheduledTime: Calendar.current.date(from: DateComponents(hour: 5, minute: 30)),
                      difficulty: .elite)
            ]
        case .study:
            return [
                Habit(name: "Read for 30 Minutes", icon: "book.fill", colorHex: "#F59E0B",
                      category: .study, type: .duration, durationMinutes: 30, difficulty: .medium),
                Habit(name: "Study Session", icon: "graduationcap.fill", colorHex: "#3B82F6",
                      category: .study, type: .duration, durationMinutes: 60, difficulty: .hard),
                Habit(name: "Review Notes", icon: "doc.text.fill", colorHex: "#22C55E",
                      category: .study, type: .completion, difficulty: .easy)
            ]
        default:
            return []
        }
    }
}

// MARK: - User Rank
enum UserRank: String, Codable, CaseIterable {
    case novice = "novice"
    case apprentice = "apprentice"
    case disciple = "disciple"
    case warrior = "warrior"
    case champion = "champion"
    case master = "master"
    case grandmaster = "grandmaster"
    case legend = "legend"
    case forge = "forge"

    var displayName: String {
        switch self {
        case .novice: return "Novice"
        case .apprentice: return "Apprentice"
        case .disciple: return "Disciple"
        case .warrior: return "Warrior"
        case .champion: return "Champion"
        case .master: return "Master"
        case .grandmaster: return "Grandmaster"
        case .legend: return "Legend"
        case .forge: return "FORGE"
        }
    }

    var emoji: String {
        switch self {
        case .novice: return "🌱"
        case .apprentice: return "⚡"
        case .disciple: return "🔥"
        case .warrior: return "⚔️"
        case .champion: return "🏆"
        case .master: return "💎"
        case .grandmaster: return "👑"
        case .legend: return "🌟"
        case .forge: return "🔱"
        }
    }

    var minLevel: Int {
        switch self {
        case .novice: return 1
        case .apprentice: return 5
        case .disciple: return 10
        case .warrior: return 20
        case .champion: return 35
        case .master: return 50
        case .grandmaster: return 75
        case .legend: return 100
        case .forge: return 150
        }
    }

    static func rankForLevel(_ level: Int) -> UserRank {
        let ranks = UserRank.allCases.reversed()
        return ranks.first { level >= $0.minLevel } ?? .novice
    }

    static func xpRequired(forLevel level: Int) -> Int {
        // Exponential growth: each level requires more XP
        if level <= 1 { return 0 }
        return Int(Double(level - 1) * 100 * pow(1.15, Double(level - 2)))
    }
}

// MARK: - App Theme
enum AppTheme: String, Codable, CaseIterable {
    case darkForge = "darkForge"
    case midnightBlue = "midnightBlue"
    case deepGreen = "deepGreen"
    case neonPurple = "neonPurple"
    case lightClear = "lightClear"

    var displayName: String {
        switch self {
        case .darkForge: return "Dark Forge"
        case .midnightBlue: return "Midnight Blue"
        case .deepGreen: return "Deep Green"
        case .neonPurple: return "Neon Purple"
        case .lightClear: return "Light & Clear"
        }
    }

    var isPremium: Bool {
        switch self {
        case .darkForge, .lightClear: return false
        default: return true
        }
    }
}
