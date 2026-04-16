import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var isPermissionGranted = false

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, _ in
            DispatchQueue.main.async {
                self.isPermissionGranted = granted
            }
        }
    }

    // MARK: - Schedule Habit Reminder
    func scheduleHabitReminder(for habit: Habit) {
        guard let scheduledTime = habit.scheduledTime else { return }

        let reminderTime = scheduledTime.addingTimeInterval(-Double(habit.reminderMinutesBefore) * 60)
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = habitReminderContent(for: habit, type: .upcoming)
        let request = UNNotificationRequest(identifier: "habit_\(habit.id)_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)

        // Schedule the "on time" notification
        let onTimeComponents = Calendar.current.dateComponents([.hour, .minute], from: scheduledTime)
        let onTimeTrigger = UNCalendarNotificationTrigger(dateMatching: onTimeComponents, repeats: true)
        let onTimeContent = habitReminderContent(for: habit, type: .due)
        let onTimeRequest = UNNotificationRequest(identifier: "habit_\(habit.id)_due", content: onTimeContent, trigger: onTimeTrigger)
        UNUserNotificationCenter.current().add(onTimeRequest)

        // Schedule missed notification (15 min after)
        let missedTime = scheduledTime.addingTimeInterval(15 * 60)
        let missedComponents = Calendar.current.dateComponents([.hour, .minute], from: missedTime)
        let missedTrigger = UNCalendarNotificationTrigger(dateMatching: missedComponents, repeats: true)
        let missedContent = habitReminderContent(for: habit, type: .late)
        let missedRequest = UNNotificationRequest(identifier: "habit_\(habit.id)_late", content: missedContent, trigger: missedTrigger)
        UNUserNotificationCenter.current().add(missedRequest)
    }

    func cancelHabitReminders(for habit: Habit) {
        let ids = [
            "habit_\(habit.id)_reminder",
            "habit_\(habit.id)_due",
            "habit_\(habit.id)_late"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func scheduleAllHabitReminders(habits: [Habit]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        habits.filter { $0.isActive && $0.scheduledTime != nil }.forEach { scheduleHabitReminder(for: $0) }
        scheduleDailyCheckIn()
        scheduleDailySummary()
        scheduleMorningMotivation()
    }

    // MARK: - Daily Check-In (Morning)
    func scheduleDailyCheckIn() {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning, Forger! 🔥"
        content.body = "Your daily mission awaits. Ready to forge your best day?"
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"

        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_checkin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Evening Summary
    func scheduleDailySummary() {
        let content = UNMutableNotificationContent()
        content.title = "Day Complete — Review Your Forge 🏆"
        content.body = "See how you performed today. Your discipline score is waiting."
        content.sound = .default

        var components = DateComponents()
        components.hour = 21
        components.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_summary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Morning Motivation
    func scheduleMorningMotivation() {
        let quotes = [
            "The discipline you build today is the freedom you'll enjoy tomorrow.",
            "One more day of discipline. That's all it takes.",
            "Champions are made in the moments they don't feel like it.",
            "Your future self is counting on today's version of you.",
            "Small wins compound into massive results. Start now."
        ]
        let quote = quotes.randomElement() ?? "Start forging. 🔥"

        let content = UNMutableNotificationContent()
        content.title = "Virtue Forge — Daily Motivation"
        content.body = quote
        content.sound = .default

        var components = DateComponents()
        components.hour = 5
        components.minute = 45
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_motivation", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Streak Protection
    func scheduleStreakProtectionAlert(currentStreak: Int) {
        guard currentStreak >= 7 else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Protect Your \(currentStreak)-Day Streak!"
        content.body = "You haven't completed today's habits yet. Don't break the chain."
        content.sound = UNNotificationSound.defaultCritical

        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_protection", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Snooze Penalty Alert
    func sendSnoozePenaltyNotification(habitName: String, pointsLost: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Snooze Penalty 😬"
        content.body = "You snoozed '\(habitName)' and lost \(pointsLost) points. Don't let it happen again."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "snooze_penalty_\(UUID())", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Achievement Notification
    func sendAchievementNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! \(achievement.icon)"
        content.body = "\(achievement.title) — \(achievement.description)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(achievement.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Content Builder
    private func habitReminderContent(for habit: Habit, type: ReminderType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        switch type {
        case .upcoming:
            content.title = "⏰ Coming Up: \(habit.name)"
            content.body = "Starting in \(habit.reminderMinutesBefore) minutes. Get ready!"
        case .due:
            content.title = "\(habit.icon) Time for \(habit.name)!"
            content.body = "It's time. Complete this for \(habit.rewardPoints) points. Let's go! 🔥"
        case .late:
            content.title = "⚠️ \(habit.name) is overdue"
            content.body = "You still have time. Complete it now — don't lose that streak!"
        }
        content.sound = .default
        content.categoryIdentifier = "HABIT_ACTION"
        content.userInfo = ["habitId": habit.id.uuidString]
        return content
    }

    enum ReminderType { case upcoming, due, late }

    // MARK: - Register Categories
    func registerNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE",
            title: "Complete ✅",
            options: [.foreground]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze (-pts) ⏰",
            options: []
        )
        let skipAction = UNNotificationAction(
            identifier: "SKIP",
            title: "Skip",
            options: [.destructive]
        )

        let habitCategory = UNNotificationCategory(
            identifier: "HABIT_ACTION",
            actions: [completeAction, snoozeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )

        let checkInCategory = UNNotificationCategory(
            identifier: "DAILY_CHECKIN",
            actions: [UNNotificationAction(identifier: "OPEN_APP", title: "Open FORGE 🔥", options: [.foreground])],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([habitCategory, checkInCategory])
    }
}
