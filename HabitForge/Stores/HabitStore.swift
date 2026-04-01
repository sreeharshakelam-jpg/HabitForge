import Foundation
import SwiftUI
import Combine

// MARK: - Habit Store (Main State Management)
class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var todayEntries: [HabitEntry] = []
    @Published var allEntries: [HabitEntry] = []
    @Published var userProfile: UserProfile = UserProfile()
    @Published var achievements: [Achievement] = AchievementLibrary.all
    @Published var dailyReports: [DailyReport] = []
    @Published var shouldShowDailySummary = false
    @Published var isInComebackMode = false

    weak var gamificationEngine: GamificationEngine?
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        loadAll()
        refreshTodayEntries()
        checkComebackMode()
    }

    // MARK: - Load / Save
    func loadAll() {
        loadHabits()
        loadEntries()
        loadUserProfile()
        loadAchievements()
        loadDailyReports()
    }

    private func loadHabits() {
        if let data = defaults.data(forKey: "habits"),
           let decoded = try? decoder.decode([Habit].self, from: data) {
            habits = decoded.sorted { $0.sortOrder < $1.sortOrder }
        }
    }

    private func loadEntries() {
        if let data = defaults.data(forKey: "entries"),
           let decoded = try? decoder.decode([HabitEntry].self, from: data) {
            allEntries = decoded
        }
    }

    private func loadUserProfile() {
        if let data = defaults.data(forKey: "userProfile"),
           let decoded = try? decoder.decode(UserProfile.self, from: data) {
            userProfile = decoded
        }
    }

    private func loadAchievements() {
        if let data = defaults.data(forKey: "achievements"),
           let decoded = try? decoder.decode([Achievement].self, from: data) {
            // Merge saved state into library
            var merged = AchievementLibrary.all
            for (i, achievement) in merged.enumerated() {
                if let saved = decoded.first(where: { $0.id == achievement.id }) {
                    merged[i] = saved
                }
            }
            achievements = merged
        }
    }

    private func loadDailyReports() {
        if let data = defaults.data(forKey: "dailyReports"),
           let decoded = try? decoder.decode([DailyReport].self, from: data) {
            dailyReports = decoded
        }
    }

    func saveAll() {
        saveHabits()
        saveEntries()
        saveUserProfile()
        saveAchievements()
        saveDailyReports()
    }

    private func saveHabits() {
        if let data = try? encoder.encode(habits) {
            defaults.set(data, forKey: "habits")
        }
    }

    private func saveEntries() {
        if let data = try? encoder.encode(allEntries) {
            defaults.set(data, forKey: "entries")
        }
    }

    func saveUserProfile() {
        if let data = try? encoder.encode(userProfile) {
            defaults.set(data, forKey: "userProfile")
        }
    }

    private func saveAchievements() {
        if let data = try? encoder.encode(achievements) {
            defaults.set(data, forKey: "achievements")
        }
    }

    private func saveDailyReports() {
        if let data = try? encoder.encode(dailyReports) {
            defaults.set(data, forKey: "dailyReports")
        }
    }

    // MARK: - Habit Management
    func addHabit(_ habit: Habit) {
        var newHabit = habit
        newHabit = Habit(
            id: habit.id, name: habit.name, description: habit.description,
            icon: habit.icon, colorHex: habit.colorHex, category: habit.category,
            type: habit.type, frequency: habit.frequency, scheduledTime: habit.scheduledTime,
            durationMinutes: habit.durationMinutes, difficulty: habit.difficulty,
            rewardPoints: habit.rewardPoints, xpReward: habit.xpReward,
            isActive: habit.isActive, sortOrder: habits.count,
            tags: habit.tags, reminderMinutesBefore: habit.reminderMinutesBefore,
            snoozeAllowed: habit.snoozeAllowed, maxSnoozePenaltyPercent: habit.maxSnoozePenaltyPercent,
            targetValue: habit.targetValue, targetUnit: habit.targetUnit
        )
        habits.append(newHabit)
        saveHabits()
        refreshTodayEntries()
    }

    func updateHabit(_ habit: Habit) {
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
            saveHabits()
            refreshTodayEntries()
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        allEntries.removeAll { $0.habitId == habit.id }
        saveHabits()
        saveEntries()
        refreshTodayEntries()
    }

    func reorderHabits(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        for (i, _) in habits.enumerated() {
            habits[i] = Habit(
                id: habits[i].id, name: habits[i].name, description: habits[i].description,
                icon: habits[i].icon, colorHex: habits[i].colorHex, category: habits[i].category,
                type: habits[i].type, frequency: habits[i].frequency, scheduledTime: habits[i].scheduledTime,
                durationMinutes: habits[i].durationMinutes, difficulty: habits[i].difficulty,
                rewardPoints: habits[i].rewardPoints, xpReward: habits[i].xpReward,
                isActive: habits[i].isActive, sortOrder: i, tags: habits[i].tags
            )
        }
        saveHabits()
    }

    // MARK: - Today Entry Management
    func refreshTodayEntries() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayHabits = habits.filter { $0.isActive && $0.frequency.isScheduledForDate(Date()) }

        var entries: [HabitEntry] = []
        for habit in todayHabits {
            if let existing = allEntries.first(where: {
                $0.habitId == habit.id &&
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }) {
                entries.append(existing)
            } else {
                let entry = HabitEntry(
                    habitId: habit.id,
                    date: today,
                    status: .pending,
                    scheduledTime: habit.scheduledTime
                )
                entries.append(entry)
                allEntries.append(entry)
            }
        }
        todayEntries = entries.sorted { e1, e2 in
            let h1 = habits.first { $0.id == e1.habitId }
            let h2 = habits.first { $0.id == e2.habitId }
            let t1 = h1?.scheduledTime ?? Date.distantFuture
            let t2 = h2?.scheduledTime ?? Date.distantFuture
            return t1 < t2
        }
        saveEntries()
    }

    func completeHabit(_ entry: HabitEntry, value: Double? = nil) {
        guard let habit = habits.first(where: { $0.id == entry.habitId }) else { return }

        let (points, xp) = gamificationEngine?.calculateReward(for: habit, entry: entry) ?? (habit.rewardPoints, habit.xpReward)

        updateEntry(entry.id, status: .completed, completedAt: Date(), pointsEarned: points, xpEarned: xp, actualValue: value)
        updateUserStats(pointsEarned: points, xpEarned: xp)
        gamificationEngine?.checkAchievements(store: self)
        checkDailySummary()
    }

    func snoozeHabit(_ entry: HabitEntry) {
        guard let habit = habits.first(where: { $0.id == entry.habitId }) else { return }
        let newSnoozeCount = (allEntries.first { $0.id == entry.id }?.snoozeCount ?? 0) + 1
        let penaltyPoints = Int(Double(habit.rewardPoints) * Double(habit.maxSnoozePenaltyPercent) / 100.0 / 3.0)
        updateEntry(entry.id, status: .snoozed, snoozeCount: newSnoozeCount)
        userProfile.totalPoints = max(0, userProfile.totalPoints - penaltyPoints)
        userProfile.disciplineScore = max(0, userProfile.disciplineScore - 2)
        saveUserProfile()
    }

    func skipHabit(_ entry: HabitEntry) {
        updateEntry(entry.id, status: .skipped)
        userProfile.disciplineScore = max(0, userProfile.disciplineScore - 1)
        saveUserProfile()
    }

    func missHabit(_ entry: HabitEntry) {
        updateEntry(entry.id, status: .missed)
        userProfile.disciplineScore = max(0, userProfile.disciplineScore - 5)
        userProfile.currentStreak = 0
        saveUserProfile()
    }

    private func updateEntry(
        _ id: UUID,
        status: CompletionStatus? = nil,
        completedAt: Date? = nil,
        pointsEarned: Int? = nil,
        xpEarned: Int? = nil,
        snoozeCount: Int? = nil,
        actualValue: Double? = nil
    ) {
        if let idx = allEntries.firstIndex(where: { $0.id == id }) {
            if let s = status { allEntries[idx].status = s }
            if let c = completedAt { allEntries[idx].completedAt = c }
            if let p = pointsEarned { allEntries[idx].pointsEarned = p }
            if let x = xpEarned { allEntries[idx].xpEarned = x }
            if let sn = snoozeCount { allEntries[idx].snoozeCount = sn }
            if let av = actualValue { allEntries[idx].actualValue = av }
        }
        if let idx = todayEntries.firstIndex(where: { $0.id == id }) {
            if let s = status { todayEntries[idx].status = s }
            if let c = completedAt { todayEntries[idx].completedAt = c }
            if let p = pointsEarned { todayEntries[idx].pointsEarned = p }
            if let x = xpEarned { todayEntries[idx].xpEarned = x }
            if let sn = snoozeCount { todayEntries[idx].snoozeCount = sn }
            if let av = actualValue { todayEntries[idx].actualValue = av }
        }
        saveEntries()
    }

    private func updateUserStats(pointsEarned: Int, xpEarned: Int) {
        userProfile.totalPoints += pointsEarned
        userProfile.totalXP += xpEarned
        userProfile.totalHabitsCompleted += 1
        userProfile.disciplineScore = min(1000, userProfile.disciplineScore + 3)
        userProfile.rank = UserRank.rankForLevel(userProfile.level)

        // Level up check
        while userProfile.totalXP >= UserRank.xpRequired(forLevel: userProfile.level + 1) {
            userProfile.level += 1
        }

        // Update streak
        updateStreak()
        saveUserProfile()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
        let yesterdayEntries = entriesForDate(yesterday)

        if yesterdayEntries.isEmpty || yesterdayEntries.allSatisfy({ $0.status == .completed || $0.status == .skipped }) {
            // Yesterday was complete or skipped (no habits) — streak continues
            if allCompletedToday {
                userProfile.currentStreak += 1
                userProfile.longestStreak = max(userProfile.longestStreak, userProfile.currentStreak)
            }
        }
    }

    var allCompletedToday: Bool {
        let active = todayEntries.filter { $0.status != .skipped }
        return !active.isEmpty && active.allSatisfy { $0.status == .completed }
    }

    var todayCompletionRate: Double {
        let active = todayEntries.filter { $0.status != .skipped }
        guard !active.isEmpty else { return 0 }
        let completed = active.filter { $0.status == .completed }.count
        return Double(completed) / Double(active.count)
    }

    var todayPointsEarned: Int {
        todayEntries.reduce(0) { $0 + $1.pointsEarned }
    }

    // MARK: - Historical Data
    func entriesForDate(_ date: Date) -> [HabitEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func entriesForHabit(_ habitId: UUID, last days: Int) -> [HabitEntry] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return allEntries.filter {
            $0.habitId == habitId && $0.date >= startDate
        }.sorted { $0.date < $1.date }
    }

    func currentStreakForHabit(_ habitId: UUID) -> Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        while true {
            let dayEntries = allEntries.filter {
                $0.habitId == habitId && Calendar.current.isDate($0.date, inSameDayAs: date)
            }
            if let entry = dayEntries.first, entry.status == .completed {
                streak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        return streak
    }

    func weeklyCompletionRates() -> [(Date, Double)] {
        (0..<7).map { offset -> (Date, Double) in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            let dayEntries = entriesForDate(date)
            let rate = dayEntries.isEmpty ? 0.0 : Double(dayEntries.filter { $0.status == .completed }.count) / Double(dayEntries.count)
            return (date, rate)
        }.reversed()
    }

    // MARK: - Daily Reset
    func performDailyReset() {
        // Archive yesterday's report
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        createDailyReport(for: yesterday)

        // Mark all pending entries from yesterday as missed
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        for (i, entry) in allEntries.enumerated() {
            if Calendar.current.isDate(entry.date, inSameDayAs: yesterdayStart) && entry.status == .pending {
                allEntries[i].status = .missed
            }
        }

        // Refresh today
        refreshTodayEntries()
        saveAll()

        // Show summary
        DispatchQueue.main.async {
            self.shouldShowDailySummary = true
        }
    }

    private func createDailyReport(for date: Date) {
        let entries = entriesForDate(date)
        let completed = entries.filter { $0.status == .completed }.count
        let missed = entries.filter { $0.status == .missed }.count
        let skipped = entries.filter { $0.status == .skipped }.count
        let points = entries.reduce(0) { $0 + $1.pointsEarned }
        let xp = entries.reduce(0) { $0 + $1.xpEarned }
        let isPerfect = !entries.isEmpty && entries.allSatisfy { $0.status == .completed }

        if isPerfect { userProfile.perfectDays += 1 }

        let report = DailyReport(
            id: UUID(),
            date: date,
            totalHabits: entries.count,
            completedHabits: completed,
            missedHabits: missed,
            skippedHabits: skipped,
            pointsEarned: points,
            xpEarned: xp,
            isPerfectDay: isPerfect,
            streakAtEndOfDay: userProfile.currentStreak,
            disciplineScoreChange: 0,
            motivationalMessage: dailyMotivation(completionRate: Double(completed)/Double(max(entries.count, 1))),
            reflectionQuestion: randomReflectionQuestion(),
            achievements: []
        )
        dailyReports.append(report)
        saveDailyReports()
    }

    private func checkDailySummary() {
        if allCompletedToday {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.shouldShowDailySummary = true
            }
        }
    }

    private func checkComebackMode() {
        let lastActive = allEntries.sorted { $0.date > $1.date }.first?.date
        guard let last = lastActive else { return }
        let daysMissed = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        isInComebackMode = daysMissed >= 3
    }

    private func dailyMotivation(completionRate: Double) -> String {
        let messages: [String]
        switch completionRate {
        case 1.0: messages = ["Legendary performance. Keep forging.", "Perfect. You are the standard.", "Unreal. This is who you are now."]
        case 0.8...: messages = ["Excellent work. You're close to perfect.", "Almost flawless. Stay on this path.", "Outstanding effort today."]
        case 0.6...: messages = ["Good effort. Push a little harder tomorrow.", "Solid day. Now raise the bar.", "Good start. The best version of you is coming."]
        default: messages = ["Tomorrow is a new forge. Rise.", "Every champion has off days. Yours ends now.", "You slipped. That's okay. Get back up."]
        }
        return messages.randomElement() ?? "Keep forging forward."
    }

    private func randomReflectionQuestion() -> String {
        let questions = [
            "What was your biggest win today?",
            "What habit do you want to improve tomorrow?",
            "How did you feel after completing your routine?",
            "What's one thing that helped you stay consistent?",
            "What would make tomorrow 10% better?",
            "Which habit is hardest for you, and why?",
            "How has your discipline changed recently?",
            "What are you most proud of today?"
        ]
        return questions.randomElement() ?? "How did today go?"
    }

    // MARK: - Achievement Management
    func unlockAchievement(_ id: String) {
        if let idx = achievements.firstIndex(where: { $0.id == id && $0.unlockedAt == nil }) {
            achievements[idx].unlockedAt = Date()
            let ach = achievements[idx]
            userProfile.totalXP += ach.xpReward
            userProfile.totalPoints += ach.pointsReward
            saveAchievements()
            saveUserProfile()
        }
    }

    func updateAchievementProgress(_ id: String, progress: Double) {
        if let idx = achievements.firstIndex(where: { $0.id == id }) {
            achievements[idx].progress = progress
        }
    }
}
