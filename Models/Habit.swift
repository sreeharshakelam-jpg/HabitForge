import Foundation
import SwiftUI

// MARK: - Habit Model
struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var icon: String
    var colorHex: String
    var category: HabitCategory
    var type: HabitType
    var frequency: HabitFrequency
    var scheduledTime: Date?
    var durationMinutes: Int?
    var difficulty: HabitDifficulty
    var rewardPoints: Int
    var xpReward: Int
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date
    var tags: [String]
    var reminderMinutesBefore: Int
    var snoozeAllowed: Bool
    var maxSnoozePenaltyPercent: Int
    var targetValue: Double?
    var targetUnit: String?

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        icon: String = "star.fill",
        colorHex: String = "#7C3AED",
        category: HabitCategory = .wellness,
        type: HabitType = .completion,
        frequency: HabitFrequency = .daily,
        scheduledTime: Date? = nil,
        durationMinutes: Int? = nil,
        difficulty: HabitDifficulty = .medium,
        rewardPoints: Int? = nil,
        xpReward: Int? = nil,
        isActive: Bool = true,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        tags: [String] = [],
        reminderMinutesBefore: Int = 10,
        snoozeAllowed: Bool = true,
        maxSnoozePenaltyPercent: Int = 50,
        targetValue: Double? = nil,
        targetUnit: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
        self.type = type
        self.frequency = frequency
        self.scheduledTime = scheduledTime
        self.durationMinutes = durationMinutes
        self.difficulty = difficulty
        self.rewardPoints = rewardPoints ?? difficulty.defaultPoints
        self.xpReward = xpReward ?? difficulty.defaultXP
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.tags = tags
        self.reminderMinutesBefore = reminderMinutesBefore
        self.snoozeAllowed = snoozeAllowed
        self.maxSnoozePenaltyPercent = maxSnoozePenaltyPercent
        self.targetValue = targetValue
        self.targetUnit = targetUnit
    }

    var color: Color {
        Color(hex: colorHex) ?? .purple
    }
}

// MARK: - Habit Category
enum HabitCategory: String, Codable, CaseIterable {
    case fitness = "fitness"
    case wellness = "wellness"
    case mindfulness = "mindfulness"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case study = "study"
    case work = "work"
    case social = "social"
    case creativity = "creativity"
    case finance = "finance"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .wellness: return "Wellness"
        case .mindfulness: return "Mindfulness"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .study: return "Study"
        case .work: return "Work"
        case .social: return "Social"
        case .creativity: return "Creativity"
        case .finance: return "Finance"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .fitness: return "flame.fill"
        case .wellness: return "heart.fill"
        case .mindfulness: return "brain.head.profile"
        case .nutrition: return "leaf.fill"
        case .sleep: return "moon.stars.fill"
        case .study: return "book.fill"
        case .work: return "briefcase.fill"
        case .social: return "person.2.fill"
        case .creativity: return "paintbrush.fill"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .fitness: return Color(hex: "#EF4444") ?? .red
        case .wellness: return Color(hex: "#10B981") ?? .green
        case .mindfulness: return Color(hex: "#8B5CF6") ?? .purple
        case .nutrition: return Color(hex: "#22C55E") ?? .green
        case .sleep: return Color(hex: "#6366F1") ?? .indigo
        case .study: return Color(hex: "#F59E0B") ?? .yellow
        case .work: return Color(hex: "#3B82F6") ?? .blue
        case .social: return Color(hex: "#EC4899") ?? .pink
        case .creativity: return Color(hex: "#F97316") ?? .orange
        case .finance: return Color(hex: "#14B8A6") ?? .teal
        case .custom: return Color(hex: "#7C3AED") ?? .purple
        }
    }
}

// MARK: - Habit Type
enum HabitType: String, Codable, CaseIterable {
    case completion = "completion"       // Simple yes/no
    case timeBased = "timeBased"         // Must complete at specific time
    case duration = "duration"           // Must be done for X minutes
    case quantity = "quantity"           // Target a number (e.g. 8 glasses of water)
    case avoidance = "avoidance"         // Avoid doing something
    case streak = "streak"               // Build a streak

    var displayName: String {
        switch self {
        case .completion: return "Completion"
        case .timeBased: return "Time-Based"
        case .duration: return "Duration"
        case .quantity: return "Quantity"
        case .avoidance: return "Avoidance"
        case .streak: return "Streak"
        }
    }

    var description: String {
        switch self {
        case .completion: return "Simple check-off habit"
        case .timeBased: return "Complete at a specific time"
        case .duration: return "Complete for a set duration"
        case .quantity: return "Hit a daily target number"
        case .avoidance: return "Avoid doing this thing"
        case .streak: return "Maintain a daily streak"
        }
    }

    var icon: String {
        switch self {
        case .completion: return "checkmark.circle.fill"
        case .timeBased: return "clock.fill"
        case .duration: return "timer"
        case .quantity: return "number.circle.fill"
        case .avoidance: return "xmark.circle.fill"
        case .streak: return "flame.fill"
        }
    }
}

// MARK: - Habit Frequency
struct HabitFrequency: Codable, Equatable {
    var type: FrequencyType
    var customDays: [Int]  // 1=Mon, 2=Tue, ... 7=Sun
    var timesPerWeek: Int

    static let daily = HabitFrequency(type: .daily, customDays: [], timesPerWeek: 7)
    static let weekdays = HabitFrequency(type: .weekdays, customDays: [1,2,3,4,5], timesPerWeek: 5)
    static let weekends = HabitFrequency(type: .weekends, customDays: [6,7], timesPerWeek: 2)

    var displayName: String {
        switch type {
        case .daily: return "Every Day"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom:
            let dayNames = customDays.sorted().map { dayShortName($0) }.joined(separator: ", ")
            return dayNames.isEmpty ? "Custom" : dayNames
        case .xTimesPerWeek: return "\(timesPerWeek)x per week"
        }
    }

    private func dayShortName(_ day: Int) -> String {
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return names[safe: day - 1] ?? "?"
    }

    func isScheduledForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let adjustedWeekday = weekday == 1 ? 7 : weekday - 1 // Convert Sun=1 to Mon=1 format

        switch type {
        case .daily: return true
        case .weekdays: return adjustedWeekday <= 5
        case .weekends: return adjustedWeekday >= 6
        case .custom: return customDays.contains(adjustedWeekday)
        case .xTimesPerWeek: return true // For simplicity, always show
        }
    }
}

enum FrequencyType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case custom = "custom"
    case xTimesPerWeek = "xTimesPerWeek"
}

// MARK: - Habit Difficulty
enum HabitDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case elite = "elite"

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .elite: return "Elite"
        }
    }

    var defaultPoints: Int {
        switch self {
        case .easy: return 10
        case .medium: return 25
        case .hard: return 50
        case .elite: return 100
        }
    }

    var defaultXP: Int {
        switch self {
        case .easy: return 5
        case .medium: return 15
        case .hard: return 30
        case .elite: return 60
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .elite: return .purple
        }
    }

    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        case .elite: return "crown.fill"
        }
    }
}

// MARK: - Habit Entry (Completion Record)
struct HabitEntry: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    let date: Date
    var status: CompletionStatus
    var completedAt: Date?
    var scheduledTime: Date?
    var pointsEarned: Int
    var xpEarned: Int
    var snoozeCount: Int
    var notes: String
    var actualValue: Double?

    init(
        id: UUID = UUID(),
        habitId: UUID,
        date: Date = Date(),
        status: CompletionStatus = .pending,
        completedAt: Date? = nil,
        scheduledTime: Date? = nil,
        pointsEarned: Int = 0,
        xpEarned: Int = 0,
        snoozeCount: Int = 0,
        notes: String = "",
        actualValue: Double? = nil
    ) {
        self.id = id
        self.habitId = habitId
        self.date = date
        self.status = status
        self.completedAt = completedAt
        self.scheduledTime = scheduledTime
        self.pointsEarned = pointsEarned
        self.xpEarned = xpEarned
        self.snoozeCount = snoozeCount
        self.notes = notes
        self.actualValue = actualValue
    }

    var timingStatus: TimingStatus {
        guard let completed = completedAt, let scheduled = scheduledTime else {
            return .noSchedule
        }
        let diff = completed.timeIntervalSince(scheduled)
        if diff <= 0 { return .early }
        if diff <= 300 { return .onTime }
        if diff <= 900 { return .late }
        return .veryLate
    }
}

enum CompletionStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
    case snoozed = "snoozed"
    case skipped = "skipped"
    case missed = "missed"
    case partiallyCompleted = "partiallyCompleted"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .snoozed: return "Snoozed"
        case .skipped: return "Skipped"
        case .missed: return "Missed"
        case .partiallyCompleted: return "Partial"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .snoozed: return "clock.badge.exclamationmark"
        case .skipped: return "minus.circle"
        case .missed: return "xmark.circle.fill"
        case .partiallyCompleted: return "circle.righthalf.filled"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .completed: return .green
        case .snoozed: return .yellow
        case .skipped: return .gray
        case .missed: return .red
        case .partiallyCompleted: return .orange
        }
    }
}

enum TimingStatus {
    case early, onTime, late, veryLate, noSchedule

    var bonusMultiplier: Double {
        switch self {
        case .early: return 1.2
        case .onTime: return 1.0
        case .late: return 0.8
        case .veryLate: return 0.6
        case .noSchedule: return 1.0
        }
    }

    var label: String {
        switch self {
        case .early: return "Early Bird"
        case .onTime: return "On Time"
        case .late: return "Late"
        case .veryLate: return "Very Late"
        case .noSchedule: return ""
        }
    }
}
