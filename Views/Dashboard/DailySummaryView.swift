import SwiftUI

// MARK: - Daily Check-In View
struct DailyCheckInView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ForgeSpacing.lg) {
                        // Header
                        VStack(spacing: 8) {
                            Text(greetingEmoji)
                                .font(.system(size: 56))
                            Text(greeting)
                                .font(ForgeTypography.h1)
                                .foregroundColor(ForgeColor.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(motivationMessage)
                                .font(ForgeTypography.bodyM)
                                .foregroundColor(ForgeColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, ForgeSpacing.xl)

                        // Today's habits preview
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TODAY'S MISSION")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.textTertiary)
                                .tracking(2)

                            ForEach(habitStore.todayEntries.prefix(5)) { entry in
                                if let habit = habitStore.habits.first(where: { $0.id == entry.habitId }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: habit.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(habit.color)
                                            .frame(width: 24)

                                        Text(habit.name)
                                            .font(ForgeTypography.h4)
                                            .foregroundColor(ForgeColor.textPrimary)

                                        Spacer()

                                        if let time = habit.scheduledTime {
                                            Text(time.timeString)
                                                .font(ForgeTypography.labelXS)
                                                .foregroundColor(ForgeColor.textTertiary)
                                        }

                                        Text("+\(habit.rewardPoints)")
                                            .font(ForgeTypography.labelXS)
                                            .foregroundColor(ForgeColor.accent)
                                    }
                                    .padding(12)
                                    .background(ForgeColor.card)
                                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                                }
                            }

                            if habitStore.todayEntries.count > 5 {
                                Text("+\(habitStore.todayEntries.count - 5) more habits")
                                    .font(ForgeTypography.labelXS)
                                    .foregroundColor(ForgeColor.textTertiary)
                                    .padding(.horizontal, 4)
                            }
                        }

                        // Streak reminder
                        if habitStore.userProfile.currentStreak > 0 {
                            HStack(spacing: 10) {
                                Text("🔥")
                                    .font(.system(size: 24))
                                Text("You have a \(habitStore.userProfile.currentStreak)-day streak! Don't break it today.")
                                    .font(ForgeTypography.labelM)
                                    .foregroundColor(ForgeColor.textPrimary)
                            }
                            .padding(ForgeSpacing.md)
                            .background(Color(hex: "#1A0800") ?? .black)
                            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(.orange.opacity(0.3), lineWidth: 1))
                        }

                        // CTA Button
                        Button {
                            UserDefaults.standard.set(Date(), forKey: "lastDailyCheckIn")
                            ForgeHaptics.success()
                            dismiss()
                        } label: {
                            Text("Let's Forge! ⚡")
                                .font(ForgeTypography.h3)
                                .foregroundColor(ForgeColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(18)
                                .background(ForgeColor.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
                                .shadow(color: ForgeColor.accent.opacity(0.3), radius: 12)
                        }
                        .buttonStyle(.plain)
                        .pressEffect()
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        UserDefaults.standard.set(Date(), forKey: "lastDailyCheckIn")
                        dismiss()
                    }
                    .foregroundColor(ForgeColor.textTertiary)
                }
            }
        }
    }

    var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<9: return "🌅"
        case 9..<12: return "☀️"
        case 12..<17: return "⚡"
        case 17..<21: return "🌆"
        default: return "🌙"
        }
    }

    var greeting: String {
        let name = habitStore.userProfile.name
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening")
        return "\(greeting)\(name.isEmpty ? "" : ", \(name)")."
    }

    var motivationMessage: String {
        gamificationEngine.getMotivationMessage(for: habitStore.userProfile)
    }
}

// MARK: - Daily Summary View
struct DailySummaryView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @Environment(\.dismiss) var dismiss
    @State private var reflection = ""
    @State private var showAchievements = false
    @State private var animateProgress = false

    var todayReport: DailyReport? {
        habitStore.dailyReports.last
    }

    var completionRate: Double { habitStore.todayCompletionRate }
    var grade: DayGrade {
        switch completionRate {
        case 1.0: return .perfect
        case 0.8...: return .excellent
        case 0.6...: return .good
        case 0.4...: return .okay
        default: return .poor
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ForgeSpacing.lg) {
                        // Grade Hero
                        gradeHeroSection

                        // Stats
                        statsSection

                        // Completed habits
                        completedSection

                        // Missed habits
                        if !missedEntries.isEmpty {
                            missedSection
                        }

                        // New Achievements
                        if !gamificationEngine.newAchievements.isEmpty {
                            newAchievementsSection
                        }

                        // Reflection
                        reflectionSection

                        // Tomorrow button
                        Button {
                            habitStore.shouldShowDailySummary = false
                            gamificationEngine.newAchievements.removeAll()
                            dismiss()
                        } label: {
                            Text("See You Tomorrow ⚡")
                                .font(ForgeTypography.h3)
                                .foregroundColor(ForgeColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(18)
                                .background(ForgeColor.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
                        }
                        .buttonStyle(.plain)
                        .pressEffect()
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.top, ForgeSpacing.md)
                }
            }
            .navigationTitle("Day Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { withAnimation(.spring(response: 0.8).delay(0.3)) { animateProgress = true } }
    }

    var gradeHeroSection: some View {
        VStack(spacing: ForgeSpacing.md) {
            ZStack {
                ForgeProgressRing(
                    progress: animateProgress ? completionRate : 0,
                    lineWidth: 10,
                    size: 120,
                    gradient: LinearGradient(colors: [grade.color, grade.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                VStack(spacing: 2) {
                    Text("\(Int(completionRate * 100))%")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(ForgeColor.textPrimary)
                    Text(grade.emoji)
                        .font(.system(size: 20))
                }
            }

            Text(grade.displayName.uppercased())
                .font(ForgeTypography.labelS)
                .foregroundColor(grade.color)
                .tracking(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(grade.color.opacity(0.1))
                .clipShape(Capsule())

            Text(grade.message)
                .font(ForgeTypography.h3)
                .foregroundColor(ForgeColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(ForgeSpacing.xl)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
    }

    var statsSection: some View {
        HStack(spacing: 10) {
            ScorePill(label: "Completed", value: "\(completedEntries.count)", color: ForgeColor.success, icon: "checkmark.circle.fill")
            ScorePill(label: "Points", value: "+\(habitStore.todayPointsEarned)", color: ForgeColor.accent, icon: "bolt.fill")
            ScorePill(label: "Streak", value: "\(habitStore.userProfile.currentStreak)🔥", color: .orange, icon: "flame.fill")
        }
    }

    var completedEntries: [HabitEntry] {
        habitStore.todayEntries.filter { $0.status == .completed }
    }

    var missedEntries: [HabitEntry] {
        habitStore.todayEntries.filter { $0.status == .missed || $0.status == .pending }
    }

    var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMPLETED (\(completedEntries.count))")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.success)
                .tracking(2)

            ForEach(completedEntries) { entry in
                if let habit = habitStore.habits.first(where: { $0.id == entry.habitId }) {
                    SummaryHabitRow(habit: habit, entry: entry, isCompleted: true)
                }
            }
        }
    }

    var missedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MISSED (\(missedEntries.count))")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.error)
                .tracking(2)

            ForEach(missedEntries) { entry in
                if let habit = habitStore.habits.first(where: { $0.id == entry.habitId }) {
                    SummaryHabitRow(habit: habit, entry: entry, isCompleted: false)
                }
            }
        }
    }

    var newAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🏆 NEW ACHIEVEMENTS")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.warning)
                .tracking(2)

            ForEach(gamificationEngine.newAchievements) { ach in
                HStack(spacing: 12) {
                    Text(ach.icon)
                        .font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ach.title)
                            .font(ForgeTypography.h4)
                            .foregroundColor(ForgeColor.textPrimary)
                        Text(ach.description)
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textSecondary)
                    }
                    Spacer()
                    Text(ach.rarity.displayName)
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ach.rarity.color)
                }
                .padding(ForgeSpacing.md)
                .background(ForgeColor.card)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ach.rarity.color.opacity(0.3), lineWidth: 1))
            }
        }
    }

    var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAILY REFLECTION")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)

            Text(habitStore.dailyReports.last?.reflectionQuestion ?? "How did today go?")
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.textPrimary)

            TextField("Write your reflection...", text: $reflection, axis: .vertical)
                .font(ForgeTypography.bodyM)
                .foregroundColor(ForgeColor.textPrimary)
                .lineLimit(4, reservesSpace: true)
                .padding(ForgeSpacing.md)
                .background(ForgeColor.card)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(ForgeColor.border, lineWidth: 1))
        }
    }
}

struct SummaryHabitRow: View {
    let habit: Habit
    let entry: HabitEntry
    let isCompleted: Bool

    private let missedQuotes = [
        "Tomorrow is a new forge. Rise.",
        "Every champion has off days. Yours ends now.",
        "You slipped. That's okay. Get back up.",
        "The comeback is always stronger than the setback.",
        "One miss doesn't define you — what you do next does.",
        "Discipline is choosing between what you want now and what you want most.",
        "Fall seven times, stand up eight.",
        "It's not about how hard you fall. It's about how fast you get back up."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: habit.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCompleted ? habit.color : ForgeColor.textTertiary)
                    .frame(width: 20)
                Text(habit.name)
                    .font(ForgeTypography.labelM)
                    .foregroundColor(isCompleted ? .white : ForgeColor.textSecondary)
                Spacer()
                if isCompleted {
                    Text("+\(entry.pointsEarned) pts")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.accent)
                } else {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(ForgeColor.error.opacity(0.6))
                }
            }

            if !isCompleted {
                Text("💪 \"\(missedQuotes[abs(habit.name.hashValue) % missedQuotes.count])\"")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.warning.opacity(0.8))
                    .italic()
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
    }
}
