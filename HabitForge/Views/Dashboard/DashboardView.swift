import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var showAddHabit = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showGameNotification = false

    var body: some View {
        ZStack(alignment: .top) {
            ForgeColor.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    DashboardHeader()
                        .padding(.horizontal, ForgeSpacing.md)
                        .padding(.top, 16)

                    // Hero Stats
                    HeroStatsCard()
                        .padding(.horizontal, ForgeSpacing.md)
                        .padding(.top, ForgeSpacing.md)

                    // Motivation Banner (comeback mode or streak)
                    if habitStore.isInComebackMode {
                        ComebackBanner()
                            .padding(.horizontal, ForgeSpacing.md)
                            .padding(.top, ForgeSpacing.md)
                    } else if habitStore.userProfile.currentStreak > 0 {
                        StreakBanner(streak: habitStore.userProfile.currentStreak)
                            .padding(.horizontal, ForgeSpacing.md)
                            .padding(.top, ForgeSpacing.md)
                    }

                    // Today's Section Title
                    HStack {
                        Text("TODAY'S FORGE")
                            .font(ForgeTypography.labelS)
                            .foregroundColor(ForgeColor.textTertiary)
                            .tracking(2)
                        Spacer()
                        Text("\(completedCount)/\(habitStore.todayEntries.count)")
                            .font(ForgeTypography.labelM)
                            .foregroundColor(ForgeColor.textSecondary)
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.top, ForgeSpacing.xl)
                    .padding(.bottom, ForgeSpacing.sm)

                    // Habit Cards
                    LazyVStack(spacing: 10) {
                        ForEach(habitStore.todayEntries) { entry in
                            if let habit = habitStore.habits.first(where: { $0.id == entry.habitId }) {
                                HabitRowCard(habit: habit, entry: entry)
                                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                            }
                        }

                        if habitStore.todayEntries.isEmpty {
                            EmptyTodayState()
                                .padding(.top, ForgeSpacing.xl)
                        }
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .animation(.spring(response: 0.4), value: habitStore.todayEntries.count)

                    // Add Habit Button
                    Button {
                        ForgeHaptics.impact(.medium)
                        showAddHabit = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Add Habit")
                                .font(ForgeTypography.h4)
                        }
                        .foregroundColor(ForgeColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                                .stroke(ForgeColor.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.top, ForgeSpacing.md)

                    Spacer(minLength: 100)
                }
            }

            // Floating Game Notifications
            VStack {
                ForEach(gamificationEngine.activeNotifications) { notification in
                    GameNotificationToast(notification: notification)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(response: 0.4), value: gamificationEngine.activeNotifications.count)
            .padding(.top, 60)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddHabit) {
            AddHabitView()
                .environmentObject(habitStore)
        }
    }

    var completedCount: Int {
        habitStore.todayEntries.filter { $0.status == .completed }.count
    }
}

// MARK: - Dashboard Header
struct DashboardHeader: View {
    @EnvironmentObject var habitStore: HabitStore

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late night hustle"
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting.uppercased())
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Text(habitStore.userProfile.name.isEmpty ? "Forger" : habitStore.userProfile.name)
                    .font(ForgeTypography.h1)
                    .foregroundColor(ForgeColor.textPrimary)
            }

            Spacer()

            // Avatar + Level
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(ForgeColor.accentGradient)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(habitStore.userProfile.avatarEmoji)
                            .font(.system(size: 22))
                    )

                Text("\(habitStore.userProfile.level)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(ForgeColor.textPrimary)
                    .padding(3)
                    .background(Circle().fill(ForgeColor.accent))
                    .offset(x: 4, y: 4)
            }
        }
    }
}

// MARK: - Hero Stats Card
struct HeroStatsCard: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine

    var body: some View {
        VStack(spacing: ForgeSpacing.md) {
            // Main ring + score
            HStack(alignment: .center, spacing: ForgeSpacing.lg) {
                // Progress Ring
                ZStack {
                    ForgeProgressRing(
                        progress: habitStore.todayCompletionRate,
                        lineWidth: 8,
                        size: 100,
                        gradient: progressGradient
                    )

                    VStack(spacing: 0) {
                        Text("\(Int(habitStore.todayCompletionRate * 100))%")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(ForgeColor.textPrimary)
                        Text("Done")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textSecondary)
                    }
                }

                // Stats
                VStack(alignment: .leading, spacing: 10) {
                    StatRow(icon: "bolt.fill", color: ForgeColor.accent,
                            label: "Points Today", value: "\(habitStore.todayPointsEarned)")
                    StatRow(icon: "flame.fill", color: .orange,
                            label: "Streak", value: "\(habitStore.userProfile.currentStreak) days")
                    StatRow(icon: "chart.bar.fill", color: ForgeColor.success,
                            label: "Discipline", value: "\(habitStore.userProfile.disciplineScore)/1000")
                }

                Spacer()
            }

            // XP Bar
            XPBar(progress: habitStore.userProfile.levelProgress, level: habitStore.userProfile.level)
        }
        .padding(ForgeSpacing.md)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: ForgeRadius.xl)
                    .fill(ForgeColor.surfaceElevated)

                // Subtle glow based on completion
                if habitStore.todayCompletionRate > 0.8 {
                    RoundedRectangle(cornerRadius: ForgeRadius.xl)
                        .stroke(ForgeColor.success.opacity(0.3), lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: ForgeRadius.xl)
                        .stroke(ForgeColor.border, lineWidth: 1)
                }
            }
        )
        .shadow(color: habitStore.todayCompletionRate > 0.8 ? ForgeColor.success.opacity(0.1) : Color.clear, radius: 20)
    }

    var progressGradient: LinearGradient {
        if habitStore.todayCompletionRate >= 1.0 {
            return LinearGradient(colors: [ForgeColor.success, Color(hex: "#059669") ?? .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if habitStore.todayCompletionRate >= 0.6 {
            return ForgeColor.accentGradient
        } else {
            return LinearGradient(colors: [ForgeColor.warning, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct StatRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(ForgeColor.textPrimary)
                Text(label)
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
            }
        }
    }
}

// MARK: - Habit Row Card
struct HabitRowCard: View {
    @EnvironmentObject var habitStore: HabitStore
    let habit: Habit
    let entry: HabitEntry
    @State private var showDetail = false
    @State private var isCompleting = false
    @State private var showActions = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 14) {
                // Category/Status Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(entry.status == .completed ? habit.color.opacity(0.25) : ForgeColor.surfaceElevated)
                        .frame(width: 48, height: 48)

                    if isCompleting {
                        Circle()
                            .trim(from: 0, to: 0.8)
                            .stroke(habit.color, lineWidth: 2)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(isCompleting ? 360 : 0))
                            .animation(.linear(duration: 0.8).repeatForever(), value: isCompleting)
                    } else {
                        Image(systemName: entry.status == .completed ? "checkmark.circle.fill" : habit.icon)
                            .font(.system(size: entry.status == .completed ? 22 : 20, weight: .semibold))
                            .foregroundStyle(entry.status == .completed ? AnyShapeStyle(ForgeColor.habitGradient(habit)) : AnyShapeStyle(Color(hex: habit.colorHex) ?? .purple))
                    }
                }
                .shadow(color: entry.status == .completed ? habit.color.opacity(0.4) : .clear, radius: 8)

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(ForgeTypography.h4)
                            .foregroundColor(entry.status == .missed ? ForgeColor.textSecondary : .white)
                            .strikethrough(entry.status == .missed)

                        if entry.status == .completed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(ForgeColor.success)
                        }
                    }

                    HStack(spacing: 8) {
                        if let time = habit.scheduledTime {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(time.timeString)
                                    .font(ForgeTypography.labelXS)
                            }
                            .foregroundColor(isOverdue ? ForgeColor.error : ForgeColor.textTertiary)
                        }

                        Text("+\(habit.rewardPoints)pts")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ForgeColor.accent.opacity(0.1))
                            .clipShape(Capsule())

                        if entry.snoozeCount > 0 {
                            Text("Snoozed \(entry.snoozeCount)x")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.warning)
                        }
                    }
                }

                Spacer()

                // Quick Action Button
                if entry.status == .pending || entry.status == .snoozed {
                    CompleteButton(habit: habit, entry: entry)
                } else {
                    StatusBadge(status: entry.status)
                }
            }
            .padding(ForgeSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeRadius.lg)
                    .fill(entry.status == .completed ?
                          ForgeColor.card.opacity(0.6) : ForgeColor.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: ForgeRadius.lg)
                            .stroke(entryBorderColor, lineWidth: 1)
                    )
            )
            .opacity(entry.status == .missed ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEffect()
        .contextMenu {
            habitContextMenu
        }
        .sheet(isPresented: $showDetail) {
            HabitDetailView(habit: habit, entry: entry)
                .environmentObject(habitStore)
        }
    }

    var isOverdue: Bool {
        guard let scheduledTime = habit.scheduledTime, entry.status == .pending else { return false }
        return scheduledTime < Date()
    }

    var entryBorderColor: Color {
        switch entry.status {
        case .completed: return ForgeColor.success.opacity(0.25)
        case .missed: return ForgeColor.error.opacity(0.15)
        case .snoozed: return ForgeColor.warning.opacity(0.2)
        default: return ForgeColor.border
        }
    }

    @ViewBuilder
    var habitContextMenu: some View {
        if entry.status == .pending || entry.status == .snoozed {
            Button {
                withAnimation { habitStore.completeHabit(entry) }
                ForgeHaptics.success()
            } label: {
                Label("Complete", systemImage: "checkmark.circle.fill")
            }

            if habit.snoozeAllowed {
                Button {
                    habitStore.snoozeHabit(entry)
                    ForgeHaptics.impact(.rigid)
                } label: {
                    Label("Snooze (lose points)", systemImage: "clock.badge.exclamationmark")
                }
            }

            Button(role: .destructive) {
                habitStore.skipHabit(entry)
            } label: {
                Label("Skip Today", systemImage: "minus.circle")
            }
        }
    }
}

// MARK: - Complete Button
struct CompleteButton: View {
    @EnvironmentObject var habitStore: HabitStore
    let habit: Habit
    let entry: HabitEntry
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3)) { scale = 1.0 }
                habitStore.completeHabit(entry)
                ForgeHaptics.success()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(habit.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Circle()
                    .stroke(habit.color.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(habit.color)
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: CompletionStatus

    var body: some View {
        Image(systemName: status.icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(status.color)
    }
}

// MARK: - Streak Banner
struct StreakBanner: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 12) {
            FlameBadge(count: streak, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak)-Day Streak")
                    .font(ForgeTypography.h4)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("Don't break the chain. Keep forging.")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textSecondary)
            }

            Spacer()

            if streak >= 7 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ForgeColor.goldGradient)
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(Color(hex: "#1A0800") ?? .black)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeRadius.lg)
                        .stroke(
                            LinearGradient(colors: [.orange.opacity(0.5), .red.opacity(0.2)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Comeback Banner
struct ComebackBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("🦅")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text("COMEBACK MODE")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.accent)
                    .tracking(1)
                Text("Every champion has setbacks. Today, rise.")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textSecondary)
            }

            Spacer()
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(Color(hex: "#0D0A1A") ?? .black)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeRadius.lg)
                        .stroke(ForgeColor.accent.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Game Notification Toast
struct GameNotificationToast: View {
    let notification: GameNotification

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(notification.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: notificationIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(notification.color)
                )

            Text(notification.message)
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeRadius.lg)
                        .stroke(notification.color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: notification.color.opacity(0.2), radius: 12)
        .padding(.horizontal, ForgeSpacing.md)
    }

    var notificationIcon: String {
        switch notification.type {
        case .combo: return "bolt.fill"
        case .perfectDay: return "crown.fill"
        case .achievement: return "trophy.fill"
        case .levelUp: return "arrow.up.circle.fill"
        case .streakMilestone: return "flame.fill"
        }
    }
}

// MARK: - Empty State
struct EmptyTodayState: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🔥")
                .font(.system(size: 60))

            VStack(spacing: 8) {
                Text("No Habits Yet")
                    .font(ForgeTypography.h2)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("Add your first habit to start forging\nyour best self today.")
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(ForgeColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ForgeSpacing.xxl)
    }
}
