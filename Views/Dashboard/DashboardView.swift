import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var showAddHabit = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showGameNotification = false
    @State private var showWisdomLibrary = false
    @State private var showChallengeSetup = false
    @State private var showDailyGoalPicker = false
    @State private var showStreakDetail = false
    @State private var showProfileSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            ForgeColor.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    DashboardHeader(onAvatarTap: { showProfileSheet = true })
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
                        Button {
                            showStreakDetail = true
                        } label: {
                            StreakBanner(streak: habitStore.userProfile.currentStreak)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, ForgeSpacing.md)
                        .padding(.top, ForgeSpacing.md)
                    }

                    // Wisdom of the Day (Bhagavad Gita, Stoic, or modern classic)
                    DailyWisdomCard(quote: WisdomLibrary.quoteOfTheDay()) {
                        showWisdomLibrary = true
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.top, ForgeSpacing.md)

                    // Challenge Day Tracker
                    if habitStore.userProfile.challengeDays > 0 {
                        ChallengeBanner()
                            .padding(.horizontal, ForgeSpacing.md)
                            .padding(.top, ForgeSpacing.md)
                    } else {
                        Button {
                            showChallengeSetup = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Start a Challenge")
                                    .font(ForgeTypography.labelM)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(ForgeColor.accent)
                            .padding(ForgeSpacing.md)
                            .background(ForgeColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, ForgeSpacing.md)
                        .padding(.top, ForgeSpacing.md)
                    }

                    // Points progress toward daily goal
                    DailyPointsGoalBar()
                        .padding(.horizontal, ForgeSpacing.md)
                        .padding(.top, ForgeSpacing.md)

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
        .sheet(isPresented: $showWisdomLibrary) {
            WisdomLibraryView()
        }
        .sheet(isPresented: $showChallengeSetup) {
            ChallengeSetupView()
                .environmentObject(habitStore)
        }
        .sheet(isPresented: $showDailyGoalPicker) {
            DailyGoalPickerView()
                .environmentObject(habitStore)
        }
        .sheet(isPresented: $showStreakDetail) {
            StreakDetailView()
                .environmentObject(habitStore)
        }
        .sheet(isPresented: $showProfileSheet) {
            NavigationView {
                EditProfileView()
                    .environmentObject(habitStore)
            }
        }
    }

    var completedCount: Int {
        habitStore.todayEntries.filter { $0.status == .completed }.count
    }
}

// MARK: - Dashboard Header
struct DashboardHeader: View {
    @EnvironmentObject var habitStore: HabitStore
    var onAvatarTap: (() -> Void)? = nil

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

            // Avatar + Level (tappable → Profile)
            Button {
                onAvatarTap?()
            } label: {
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
            .buttonStyle(.plain)
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
                            label: "Points Today", value: "\(habitStore.todayPointsEarned)/\(habitStore.todayPossiblePoints)")
                    StatRow(icon: "flame.fill", color: .orange,
                            label: "Streak", value: "\(habitStore.userProfile.currentStreak) days")
                    StatRow(icon: "chart.bar.fill", color: ForgeColor.success,
                            label: "Disciplined Days", value: "\(habitStore.userProfile.totalDisciplinedDays) days")
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
        VStack(spacing: 0) {
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
                            .foregroundColor(entry.status == .missed ? ForgeColor.textSecondary : ForgeColor.textPrimary)
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

                    }
                }

                Spacer()

                // Quick Action Button
                if entry.status == .pending || entry.status == .snoozed {
                    CompleteButton(habit: habit, entry: entry)
                } else if entry.status == .completed {
                    // Tap completed badge to undo
                    Button {
                        withAnimation { habitStore.uncompleteHabit(entry) }
                        ForgeHaptics.impact(.medium)
                    } label: {
                        StatusBadge(status: entry.status)
                    }
                    .buttonStyle(.plain)
                } else {
                    StatusBadge(status: entry.status)
                }
            }
            .padding(ForgeSpacing.md)

            // Motivational quote when missed or overdue
            if entry.status == .missed || (isOverdue && entry.status == .pending) {
                HStack(spacing: 8) {
                    Image(systemName: entry.status == .missed ? "quote.opening" : "exclamationmark.triangle")
                        .font(.system(size: 11))
                        .foregroundColor(entry.status == .missed ? ForgeColor.textTertiary : ForgeColor.warning)
                    Text(missedQuote)
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(entry.status == .missed ? ForgeColor.textTertiary : ForgeColor.warning)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, ForgeSpacing.md)
                .padding(.bottom, ForgeSpacing.sm)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(entry.status == .completed ?
                      ForgeColor.card.opacity(0.6) : ForgeColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeRadius.lg)
                        .stroke(entryBorderColor, lineWidth: 1)
                )
        )
        .opacity(entry.status == .missed ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
        }
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

    var missedQuote: String {
        let quotes = [
            "Tomorrow is another chance to forge ahead.",
            "Missing one doesn't define you. Rising does.",
            "Champions slip. Legends get back up.",
            "The comeback is always stronger than the setback.",
            "Discipline is built one recovery at a time.",
            "Don't dwell. Just forge forward.",
            "Your best streak starts right now.",
            "Fall seven times, stand up eight."
        ]
        // Use habit ID hash for deterministic-per-habit selection
        let idx = abs(habit.id.hashValue) % quotes.count
        return quotes[idx]
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

            Button(role: .destructive) {
                habitStore.skipHabit(entry)
            } label: {
                Label("Skip Today", systemImage: "minus.circle")
            }
        } else if entry.status == .completed {
            Button {
                withAnimation { habitStore.uncompleteHabit(entry) }
                ForgeHaptics.impact(.medium)
            } label: {
                Label("Undo Completion", systemImage: "arrow.uturn.backward.circle")
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

// MARK: - Daily Points Goal Bar
struct DailyPointsGoalBar: View {
    @EnvironmentObject var habitStore: HabitStore

    var earned: Int { habitStore.todayPointsEarned }
    var goal: Int { habitStore.todayPossiblePoints }
    var completedCount: Int { habitStore.todayEntries.filter { $0.status == .completed }.count }
    var totalCount: Int { habitStore.todayEntries.count }
    var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DAILY PROGRESS")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                Text("\(completedCount)/\(totalCount) habits · \(earned)/\(goal) pts")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(progress >= 1.0 ? ForgeColor.success : ForgeColor.accent)
            }

            // Progress bar based on habit completion ratio
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ForgeColor.surfaceElevated)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress >= 1.0 ? ForgeColor.success : ForgeColor.accent)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)

            // Status messages based on habit completion
            if progress >= 1.0 {
                Text("🏆 All habits completed! Perfect day.")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.success)
                    .lineLimit(2)
            } else if progress >= 0.5 {
                Text("🔥 \(completedCount) done, \(totalCount - completedCount) to go. Keep pushing!")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.warning)
            } else if totalCount > 0 {
                Text("💪 \(totalCount - completedCount) habits waiting. Start forging!")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        )
    }
}

// MARK: - Challenge Banner
struct ChallengeBanner: View {
    @EnvironmentObject var habitStore: HabitStore

    var profile: UserProfile { habitStore.userProfile }
    var progress: Double {
        guard profile.challengeDays > 0 else { return 0 }
        return Double(profile.challengeCurrentDay) / Double(profile.challengeDays)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ForgeColor.accent)
                Text("\(profile.challengeDays)-DAY CHALLENGE")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.accent)
                    .tracking(1)
                Spacer()
                Text("Day \(profile.challengeCurrentDay)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(ForgeColor.textPrimary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ForgeColor.surfaceElevated)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ForgeColor.accentGradient)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(progress * 100))% complete")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textSecondary)
                Spacer()
                if profile.challengeBestDay > 0 && profile.challengeCurrentDay < profile.challengeBestDay {
                    Text("Best: Day \(profile.challengeBestDay)")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.warning)
                }
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(Color(hex: "#0A0F1A") ?? .black)
                .overlay(
                    RoundedRectangle(cornerRadius: ForgeRadius.lg)
                        .stroke(ForgeColor.accent.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Challenge Setup View
struct ChallengeSetupView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedDays: Int = 30

    let options = [
        (days: 21, label: "21-Day Kickstart", desc: "Build the foundation"),
        (days: 30, label: "30-Day Forge", desc: "Cement a new habit"),
        (days: 75, label: "75 Hard", desc: "The classic mental toughness test"),
        (days: 100, label: "100-Day Warrior", desc: "Transform your identity")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        Text("🏁")
                            .font(.system(size: 60))
                            .padding(.top, 20)

                        Text("Choose Your Challenge")
                            .font(ForgeTypography.h2)
                            .foregroundColor(ForgeColor.textPrimary)

                        Text("Complete all your habits every day for the chosen period. Miss a day and it resets — but you can always restart.")
                            .font(ForgeTypography.bodyM)
                            .foregroundColor(ForgeColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        ForEach(options, id: \.days) { option in
                            Button {
                                selectedDays = option.days
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.label)
                                            .font(ForgeTypography.h4)
                                            .foregroundColor(ForgeColor.textPrimary)
                                        Text(option.desc)
                                            .font(ForgeTypography.labelXS)
                                            .foregroundColor(ForgeColor.textSecondary)
                                    }
                                    Spacer()
                                    if selectedDays == option.days {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(ForgeColor.accent)
                                    } else {
                                        Circle()
                                            .stroke(ForgeColor.border, lineWidth: 2)
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                .padding(ForgeSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: ForgeRadius.lg)
                                        .fill(selectedDays == option.days ? ForgeColor.accent.opacity(0.1) : ForgeColor.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                                                .stroke(selectedDays == option.days ? ForgeColor.accent : ForgeColor.border, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, ForgeSpacing.md)

                        Button {
                            habitStore.userProfile.challengeDays = selectedDays
                            habitStore.userProfile.challengeStartDate = Date()
                            habitStore.userProfile.challengeCurrentDay = 0
                            habitStore.saveUserProfile()
                            ForgeHaptics.success()
                            dismiss()
                        } label: {
                            Text("Start \(selectedDays)-Day Challenge")
                                .font(ForgeTypography.h4)
                                .foregroundColor(ForgeColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(ForgeSpacing.md)
                                .background(ForgeColor.accentGradient)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, ForgeSpacing.md)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ForgeColor.accent)
                }
            }
        }
    }
}

// MARK: - Daily Goal Picker View
struct DailyGoalPickerView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss
    @State private var goal: Double = 100

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("⚡")
                        .font(.system(size: 60))
                        .padding(.top, 30)

                    Text("Daily Points Goal")
                        .font(ForgeTypography.h2)
                        .foregroundColor(ForgeColor.textPrimary)

                    Text("\(Int(goal))")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(ForgeColor.accent)

                    Slider(value: $goal, in: 25...500, step: 25)
                        .tint(ForgeColor.accent)
                        .padding(.horizontal, 40)

                    Text("Points you want to hit every day.\nEarned by completing your habits.")
                        .font(ForgeTypography.bodyM)
                        .foregroundColor(ForgeColor.textSecondary)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button {
                        habitStore.userProfile.dailyPointGoal = Int(goal)
                        habitStore.saveUserProfile()
                        dismiss()
                    } label: {
                        Text("Set Goal")
                            .font(ForgeTypography.h4)
                            .foregroundColor(ForgeColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(ForgeSpacing.md)
                            .background(ForgeColor.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Set Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ForgeColor.accent)
                }
            }
        }
        .onAppear { goal = Double(habitStore.userProfile.dailyPointGoal) }
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

// MARK: - Streak Detail View
struct StreakDetailView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss

    private var last14Days: [(date: Date, completed: Int, total: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<14).reversed().map { offset -> (Date, Int, Int) in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let entries = habitStore.allEntries.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let completed = entries.filter { $0.status == .completed }.count
            return (day, completed, entries.count)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: ForgeSpacing.lg) {
                        // Hero
                        VStack(spacing: 12) {
                            Text("🔥")
                                .font(.system(size: 64))
                            Text("\(habitStore.userProfile.currentStreak)")
                                .font(.system(size: 72, weight: .black, design: .rounded))
                                .foregroundColor(.orange)
                            Text("DAY STREAK")
                                .font(ForgeTypography.labelS)
                                .foregroundColor(ForgeColor.textTertiary)
                                .tracking(3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(ForgeSpacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: ForgeRadius.xl)
                                .fill(Color(hex: "#120800") ?? ForgeColor.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: ForgeRadius.xl)
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                        )

                        // Stats row
                        HStack(spacing: 10) {
                            ScorePill(
                                label: "Current",
                                value: "\(habitStore.userProfile.currentStreak)🔥",
                                color: .orange,
                                icon: "flame.fill"
                            )
                            ScorePill(
                                label: "Longest",
                                value: "\(habitStore.userProfile.longestStreak)",
                                color: ForgeColor.warning,
                                icon: "trophy.fill"
                            )
                            ScorePill(
                                label: "Total Days",
                                value: "\(habitStore.allEntries.map { Calendar.current.startOfDay(for: $0.date) }.uniqued().count)",
                                color: ForgeColor.accent,
                                icon: "calendar"
                            )
                        }

                        // 14-day history
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LAST 14 DAYS")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.textTertiary)
                                .tracking(2)

                            HStack(spacing: 6) {
                                ForEach(last14Days, id: \.date) { item in
                                    VStack(spacing: 4) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(item.completed > 0 ? .orange.opacity(0.8) : ForgeColor.card)
                                                .frame(width: 20, height: 36)
                                            if item.completed > 0 {
                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(ForgeColor.textPrimary)
                                            }
                                        }
                                        Text(item.date.dayName)
                                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                                            .foregroundColor(ForgeColor.textTertiary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))

                        // Motivation
                        let message = streakMotivation
                        Text(message)
                            .font(ForgeTypography.h4)
                            .foregroundColor(ForgeColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(ForgeSpacing.lg)
                            .frame(maxWidth: .infinity)
                            .background(ForgeColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.top, ForgeSpacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ForgeColor.accent)
                }
            }
        }
    }

    var streakMotivation: String {
        let streak = habitStore.userProfile.currentStreak
        switch streak {
        case 0: return "Start today. Every champion began at zero."
        case 1: return "Day 1 done. The hardest part is showing up."
        case 2..<7: return "Building momentum. Keep the chain alive."
        case 7..<14: return "One week strong! You're forming a real habit."
        case 14..<30: return "Two weeks in — this is becoming part of who you are."
        case 30..<75: return "A full month forged. You're unstoppable."
        case 75..<100: return "75 days of discipline. Legendary status incoming."
        default: return "100+ days. You've transcended. Keep going."
        }
    }
}

private extension Array where Element == Date {
    func uniqued() -> [Date] {
        var seen = Set<Date>()
        return filter { seen.insert($0).inserted }
    }
}
