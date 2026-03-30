import Foundation
import SwiftUI
import Combine

// MARK: - Gamification Engine
class GamificationEngine: ObservableObject {
    @Published var activeNotifications: [GameNotification] = []
    @Published var recentXPGain: Int = 0
    @Published var isLevelingUp = false
    @Published var newAchievements: [Achievement] = []
    @Published var comboMultiplier: Double = 1.0
    @Published var dailyBonusAvailable = false

    weak var habitStore: HabitStore?
    private var comboTimer: Timer?
    private var comboCount = 0

    // MARK: - Reward Calculation
    func calculateReward(for habit: Habit, entry: HabitEntry) -> (points: Int, xp: Int) {
        var points = habit.rewardPoints
        var xp = habit.xpReward

        // Timing bonus
        let timing = entry.timingStatus
        points = Int(Double(points) * timing.bonusMultiplier)
        xp = Int(Double(xp) * timing.bonusMultiplier)

        // Combo multiplier
        points = Int(Double(points) * comboMultiplier)
        xp = Int(Double(xp) * comboMultiplier)

        // Snooze penalty
        let snoozePenalty = Double(entry.snoozeCount) * 0.15
        points = Int(Double(points) * (1.0 - snoozePenalty))
        xp = Int(Double(xp) * (1.0 - snoozePenalty))

        // Streak bonus (up to +50% at 30+ day streak)
        if let store = habitStore {
            let streak = store.userProfile.currentStreak
            let streakBonus = min(Double(streak) / 60.0, 0.5)
            points = Int(Double(points) * (1.0 + streakBonus))
            xp = Int(Double(xp) * (1.0 + streakBonus))
        }

        // Perfect day bonus (first completion of the day when all others are done)
        if let store = habitStore {
            let pending = store.todayEntries.filter { $0.status == .pending && $0.id != entry.id }
            if pending.isEmpty {
                // This is the last habit — perfect day bonus!
                points = Int(Double(points) * 1.5)
                xp = Int(Double(xp) * 1.5)
                triggerPerfectDayNotification()
            }
        }

        // Update combo
        updateCombo()

        return (max(1, points), max(1, xp))
    }

    // MARK: - Combo System
    private func updateCombo() {
        comboCount += 1
        comboTimer?.invalidate()

        // Combo tiers
        switch comboCount {
        case 1: comboMultiplier = 1.0
        case 2: comboMultiplier = 1.1
        case 3: comboMultiplier = 1.25
        case 4: comboMultiplier = 1.4
        case 5...: comboMultiplier = 1.5
        default: break
        }

        if comboCount >= 2 {
            triggerComboNotification(count: comboCount)
        }

        // Reset combo after 2 hours of inactivity
        comboTimer = Timer.scheduledTimer(withTimeInterval: 7200, repeats: false) { [weak self] _ in
            self?.resetCombo()
        }
    }

    private func resetCombo() {
        comboCount = 0
        comboMultiplier = 1.0
    }

    // MARK: - Achievement Checking
    func checkAchievements(store: HabitStore) {
        let profile = store.userProfile

        // Streak achievements
        let streakAchievements = ["streak_3": 3, "streak_7": 7, "streak_14": 14,
                                   "streak_21": 21, "streak_30": 30, "streak_60": 60,
                                   "streak_100": 100, "streak_365": 365]
        for (id, required) in streakAchievements {
            if profile.currentStreak >= required {
                if store.achievements.first(where: { $0.id == id })?.isUnlocked == false {
                    store.unlockAchievement(id)
                    notifyAchievement(store.achievements.first { $0.id == id })
                }
            } else {
                let progress = Double(profile.currentStreak) / Double(required)
                store.updateAchievementProgress(id, progress: progress)
            }
        }

        // Completion achievements
        let completionAchievements = ["complete_10": 10, "complete_100": 100, "complete_1000": 1000]
        for (id, required) in completionAchievements {
            if profile.totalHabitsCompleted >= required {
                if store.achievements.first(where: { $0.id == id })?.isUnlocked == false {
                    store.unlockAchievement(id)
                    notifyAchievement(store.achievements.first { $0.id == id })
                }
            } else {
                store.updateAchievementProgress(id, progress: Double(profile.totalHabitsCompleted) / Double(required))
            }
        }

        // Perfect day achievements
        if profile.perfectDays >= 1 {
            if store.achievements.first(where: { $0.id == "perfect_1" })?.isUnlocked == false {
                store.unlockAchievement("perfect_1")
                notifyAchievement(store.achievements.first { $0.id == "perfect_1" })
            }
        }
        if profile.perfectDays >= 7 {
            if store.achievements.first(where: { $0.id == "perfect_7" })?.isUnlocked == false {
                store.unlockAchievement("perfect_7")
                notifyAchievement(store.achievements.first { $0.id == "perfect_7" })
            }
        }

        // Level achievements
        if profile.level >= 10 {
            if store.achievements.first(where: { $0.id == "level_10" })?.isUnlocked == false {
                store.unlockAchievement("level_10")
                notifyAchievement(store.achievements.first { $0.id == "level_10" })
            }
        }

        // Comeback achievement
        if store.isInComebackMode && store.allCompletedToday {
            if store.achievements.first(where: { $0.id == "comeback" })?.isUnlocked == false {
                store.unlockAchievement("comeback")
                notifyAchievement(store.achievements.first { $0.id == "comeback" })
            }
        }
    }

    // MARK: - Discipline Score
    func calculateDisciplineScore(store: HabitStore) -> Int {
        let profile = store.userProfile
        var score = 100 // Base

        // Streak bonus (up to +200)
        score += min(profile.currentStreak * 5, 200)

        // Consistency bonus
        let weeklyRates = store.weeklyCompletionRates()
        let avgRate = weeklyRates.map { $0.1 }.reduce(0, +) / Double(weeklyRates.count)
        score += Int(avgRate * 100)

        // Perfect day bonus
        score += profile.perfectDays * 10

        // Penalty for long streakless periods
        if profile.currentStreak == 0 {
            score -= 50
        }

        return max(0, min(1000, score))
    }

    func calculateConsistencyScore(store: HabitStore) -> Int {
        let last30Days = (0..<30).map { offset -> Double in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            let entries = store.entriesForDate(date)
            if entries.isEmpty { return 1.0 } // No habits that day
            let rate = Double(entries.filter { $0.status == .completed }.count) / Double(entries.count)
            return rate
        }
        let avg = last30Days.reduce(0, +) / 30.0
        return Int(avg * 100)
    }

    // MARK: - Motivation Messages
    func getMotivationMessage(for profile: UserProfile) -> String {
        if profile.currentStreak > 0 {
            return streakMessage(streak: profile.currentStreak)
        } else if profile.comebackCount > 0 {
            return comebackMessage()
        } else {
            return startingMessage()
        }
    }

    private func streakMessage(streak: Int) -> String {
        switch streak {
        case 1: return "Day 1. The journey begins. ⚡"
        case 2...6: return "\(streak) days strong. Keep going. 🔥"
        case 7...13: return "One week in! You're building momentum. 💪"
        case 14...20: return "\(streak) days! This is becoming part of you. 🧬"
        case 21...29: return "3 weeks of discipline. Science says this is a habit now. 🏆"
        case 30...59: return "The Iron Month. You are forged. ⚔️"
        case 60...99: return "\(streak) days. Diamond-level discipline. 💎"
        case 100...: return "\(streak) days. You are legendary. 👑"
        default: return "Keep forging. 🔥"
        }
    }

    private func comebackMessage() -> String {
        let messages = [
            "The phoenix returns. Welcome back. 🦅",
            "Setbacks are setups. You're back and stronger.",
            "Every champion falls. The greats get back up.",
            "Comeback mode: activated. Let's forge. 🔥"
        ]
        return messages.randomElement() ?? "Welcome back. Let's go."
    }

    private func startingMessage() -> String {
        let messages = [
            "Your discipline era starts today. ⚡",
            "One habit at a time. Let's build your legacy.",
            "The best time to start was yesterday. The next best is now. 🔥",
            "You are capable of more than you think. Prove it today."
        ]
        return messages.randomElement() ?? "Let's forge your best self. 🔥"
    }

    // MARK: - In-App Notifications
    private func triggerComboNotification(count: Int) {
        let messages = [2: "2x Combo! 🔥", 3: "3x Combo! Keep rolling! ⚡", 4: "4x Combo! You're ON FIRE! 🔱", 5: "MAX COMBO! LEGENDARY! 👑"]
        let msg = messages[min(count, 5)] ?? "\(count)x COMBO! 🔥"
        addNotification(GameNotification(message: msg, type: .combo, color: .orange))
    }

    private func triggerPerfectDayNotification() {
        addNotification(GameNotification(message: "PERFECT DAY! +50% Bonus! 🔥", type: .perfectDay, color: .green))
    }

    private func notifyAchievement(_ achievement: Achievement?) {
        guard let ach = achievement else { return }
        addNotification(GameNotification(message: "🏆 \(ach.title) Unlocked!", type: .achievement, color: ach.rarity.color))
        newAchievements.append(ach)
    }

    private func addNotification(_ notification: GameNotification) {
        DispatchQueue.main.async {
            self.activeNotifications.append(notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.activeNotifications.removeAll { $0.id == notification.id }
            }
        }
    }
}

// MARK: - Game Notification
struct GameNotification: Identifiable {
    let id = UUID()
    let message: String
    let type: NotificationType
    let color: Color

    enum NotificationType {
        case combo, perfectDay, achievement, levelUp, streakMilestone
    }
}
