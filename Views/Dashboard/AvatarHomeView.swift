import SwiftUI

// MARK: - Avatar Home (the landing tab)
// Combines the muscle-growing self-image avatar with the daily ritual:
// avatar hero on top, this-week streak strip, today's habits, plus the
// preserved dashboard widgets and Psycho-Cybernetics self-image cards.

struct AvatarHomeView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var showAddHabit = false
    @State private var showWisdomLibrary = false
    @State private var showChallengeSetup = false
    @State private var showProfileSheet = false

    private var completedCount: Int {
        habitStore.todayEntries.filter { $0.status == .completed }.count
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForgeColor.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: ForgeSpacing.md) {
                    DashboardHeader(onAvatarTap: { showProfileSheet = true })
                        .padding(.top, 16)

                    // ★ The star: muscle-growing avatar that flexes on completion
                    AvatarHeroCard()

                    // This week's streak strip
                    WeekStreakStrip()

                    // Physique progress toward next body stage
                    PhysiqueProgressCard()

                    if habitStore.isInComebackMode {
                        ComebackBanner()
                    }

                    // Daily wisdom
                    DailyWisdomCard(quote: WisdomLibrary.quoteOfTheDay()) {
                        showWisdomLibrary = true
                    }

                    // Challenge
                    if habitStore.userProfile.challengeDays > 0 {
                        ChallengeBanner()
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
                    }

                    // Daily points goal
                    DailyPointsGoalBar()

                    // Today's habits
                    todaySection

                    // Psycho-Cybernetics self-image work
                    SelfImageStatementCard()
                    DailyPrincipleCard()
                    MentalRehearsalCard()

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, ForgeSpacing.md)
            }

            // Floating game notifications
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
            AddHabitView().environmentObject(habitStore)
        }
        .sheet(isPresented: $showWisdomLibrary) {
            WisdomLibraryView()
        }
        .sheet(isPresented: $showChallengeSetup) {
            ChallengeSetupView().environmentObject(habitStore)
        }
        .sheet(isPresented: $showProfileSheet) {
            NavigationView {
                EditProfileView().environmentObject(habitStore)
            }
        }
    }

    private var todaySection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("TODAY'S RITUAL")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                Text("\(completedCount)/\(habitStore.todayEntries.count)")
                    .font(ForgeTypography.labelM)
                    .foregroundColor(ForgeColor.textSecondary)
            }
            .padding(.top, ForgeSpacing.sm)

            LazyVStack(spacing: 10) {
                ForEach(habitStore.todayEntries) { entry in
                    if let habit = habitStore.habits.first(where: { $0.id == entry.habitId }) {
                        HabitRowCard(habit: habit, entry: entry)
                            .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                    }
                }

                if habitStore.todayEntries.isEmpty {
                    EmptyTodayState().padding(.top, ForgeSpacing.md)
                }
            }
            .animation(.spring(response: 0.4), value: habitStore.todayEntries.count)

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
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.3), lineWidth: 1))
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - This Week Streak Strip (Mon–Sun)

struct WeekStreakStrip: View {
    @EnvironmentObject var habitStore: HabitStore

    private struct DayCell: Identifiable {
        let id = UUID()
        let label: String
        let dayNum: Int
        let isToday: Bool
        let isFuture: Bool
        let completed: Bool
    }

    private var week: [DayCell] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Monday as first weekday
        let weekday = cal.component(.weekday, from: today) // 1=Sun...7=Sat
        let offsetToMonday = (weekday == 1 ? 6 : weekday - 2)
        let monday = cal.date(byAdding: .day, value: -offsetToMonday, to: today)!
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return (0..<7).map { i in
            let date = cal.date(byAdding: .day, value: i, to: monday)!
            let dayStart = cal.startOfDay(for: date)
            let isToday = cal.isDate(dayStart, inSameDayAs: today)
            let isFuture = dayStart > today
            let entries = habitStore.entriesForDate(dayStart)
            let completed = entries.contains { $0.status == .completed }
            return DayCell(
                label: labels[i],
                dayNum: cal.component(.day, from: date),
                isToday: isToday,
                isFuture: isFuture,
                completed: completed
            )
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                FlameBadge(count: habitStore.userProfile.currentStreak, size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(habitStore.userProfile.currentStreak > 0
                         ? "\(habitStore.userProfile.currentStreak)-Day Streak"
                         : "Start Your Streak")
                        .font(ForgeTypography.h4)
                        .foregroundColor(ForgeColor.textPrimary)
                    Text("This week")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                }
                Spacer()
                Text(Date().formatted(.dateTime.month(.wide)))
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.textSecondary)
            }

            HStack(spacing: 6) {
                ForEach(week) { day in
                    VStack(spacing: 5) {
                        Text(day.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(day.isToday ? ForgeColor.accent : ForgeColor.textTertiary)

                        ZStack {
                            Circle()
                                .fill(cellFill(day))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().stroke(day.isToday ? ForgeColor.accent : Color.clear, lineWidth: 2)
                                )
                            if day.completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(day.dayNum)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(day.isFuture ? ForgeColor.textTertiary : ForgeColor.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        )
    }

    private func cellFill(_ day: DayCell) -> Color {
        if day.completed { return ForgeColor.success }
        if day.isToday { return ForgeColor.accent.opacity(0.15) }
        return ForgeColor.surfaceElevated
    }
}
