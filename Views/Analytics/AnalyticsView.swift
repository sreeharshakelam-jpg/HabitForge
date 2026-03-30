import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedPeriod = AnalyticsPeriod.week

    enum AnalyticsPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
    }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: ForgeSpacing.md) {
                        // Period Selector
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, ForgeSpacing.md)

                        // Key Metrics
                        keyMetricsSection

                        // Completion Chart
                        completionChartSection

                        // Discipline + Consistency
                        scoresSection

                        // Habit Breakdown
                        habitBreakdownSection

                        // Health Integration
                        if healthKitManager.isAuthorized {
                            healthInsightsSection
                        }

                        // Best / Worst Times
                        timingInsightsSection

                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, ForgeSpacing.md)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Key Metrics
    var keyMetricsSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricCard(
                    title: "Total Points",
                    value: formatNumber(habitStore.userProfile.totalPoints),
                    icon: "bolt.fill",
                    color: ForgeColor.accent,
                    trend: "+\(habitStore.todayPointsEarned) today"
                )
                MetricCard(
                    title: "Current Streak",
                    value: "\(habitStore.userProfile.currentStreak)",
                    icon: "flame.fill",
                    color: .orange,
                    trend: "Best: \(habitStore.userProfile.longestStreak)"
                )
            }
            HStack(spacing: 10) {
                MetricCard(
                    title: "Total Completed",
                    value: formatNumber(habitStore.userProfile.totalHabitsCompleted),
                    icon: "checkmark.circle.fill",
                    color: ForgeColor.success,
                    trend: "All time"
                )
                MetricCard(
                    title: "Perfect Days",
                    value: "\(habitStore.userProfile.perfectDays)",
                    icon: "crown.fill",
                    color: Color(hex: "#F59E0B") ?? .yellow,
                    trend: "All time"
                )
            }
        }
        .padding(.horizontal, ForgeSpacing.md)
    }

    // MARK: - Completion Chart
    var completionChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Completion Rate", subtitle: "Last 7 days")

            let rates = habitStore.weeklyCompletionRates()

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(rates.enumerated()), id: \.offset) { i, item in
                    let (date, rate) = item
                    VStack(spacing: 6) {
                        Text("\(Int(rate * 100))%")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(rate >= 0.8 ? ForgeColor.success : ForgeColor.textTertiary)

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ForgeColor.border)
                                .frame(width: 32, height: 80)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(rate))
                                .frame(width: 32, height: max(4, CGFloat(rate) * 80))
                                .animation(.spring(response: 0.6).delay(Double(i) * 0.05), value: rate)
                        }

                        Text(date.dayName)
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
        }
        .padding(ForgeSpacing.md)
        .forgeCard()
        .padding(.horizontal, ForgeSpacing.md)
    }

    // MARK: - Scores
    var scoresSection: some View {
        HStack(spacing: 10) {
            // Discipline Score
            VStack(spacing: 14) {
                Text("DISCIPLINE")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)

                ZStack {
                    ForgeProgressRing(
                        progress: Double(habitStore.userProfile.disciplineScore) / 1000.0,
                        lineWidth: 8,
                        size: 90,
                        gradient: ForgeColor.accentGradient
                    )
                    VStack(spacing: 0) {
                        Text("\(habitStore.userProfile.disciplineScore)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("/1000")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                    }
                }

                Text(disciplineLabel(habitStore.userProfile.disciplineScore))
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(ForgeSpacing.md)
            .forgeCard()

            // Consistency Score
            VStack(spacing: 14) {
                Text("CONSISTENCY")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)

                ZStack {
                    let consistency = Double(habitStore.userProfile.consistencyScore) / 100.0
                    ForgeProgressRing(
                        progress: consistency,
                        lineWidth: 8,
                        size: 90,
                        gradient: ForgeColor.greenGradient
                    )
                    VStack(spacing: 0) {
                        Text("\(habitStore.userProfile.consistencyScore)%")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("30d avg")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                    }
                }

                Text(consistencyLabel(habitStore.userProfile.consistencyScore))
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.success)
            }
            .frame(maxWidth: .infinity)
            .padding(ForgeSpacing.md)
            .forgeCard()
        }
        .padding(.horizontal, ForgeSpacing.md)
    }

    // MARK: - Habit Breakdown
    var habitBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Habit Performance", subtitle: "Completion by habit (last 30 days)")

            ForEach(habitStore.habits.prefix(5)) { habit in
                HabitPerformanceRow(habit: habit, store: habitStore)
            }
        }
        .padding(ForgeSpacing.md)
        .forgeCard()
        .padding(.horizontal, ForgeSpacing.md)
    }

    // MARK: - Health Insights
    var healthInsightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Health Insights", subtitle: "From Apple Health")

            HStack(spacing: 10) {
                HealthMetricCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(healthKitManager.todaySteps)",
                    target: "10,000",
                    progress: Double(healthKitManager.todaySteps) / 10000.0,
                    color: ForgeColor.success
                )
                HealthMetricCard(
                    icon: "moon.stars.fill",
                    title: "Sleep",
                    value: String(format: "%.1fh", healthKitManager.todaySleepHours),
                    target: "8h",
                    progress: healthKitManager.todaySleepHours / 8.0,
                    color: Color(hex: "#6366F1") ?? .indigo
                )
            }

            if healthKitManager.todayActiveEnergy > 0 {
                HStack(spacing: 10) {
                    HealthMetricCard(
                        icon: "flame.fill",
                        title: "Calories",
                        value: "\(Int(healthKitManager.todayActiveEnergy)) kcal",
                        target: "500 kcal",
                        progress: healthKitManager.todayActiveEnergy / 500.0,
                        color: .orange
                    )
                    if healthKitManager.mindfulnessMinutes > 0 {
                        HealthMetricCard(
                            icon: "brain.head.profile",
                            title: "Mindful",
                            value: "\(Int(healthKitManager.mindfulnessMinutes)) min",
                            target: "10 min",
                            progress: healthKitManager.mindfulnessMinutes / 10.0,
                            color: Color(hex: "#8B5CF6") ?? .purple
                        )
                    }
                }
            }
        }
        .padding(ForgeSpacing.md)
        .forgeCard()
        .padding(.horizontal, ForgeSpacing.md)
    }

    // MARK: - Timing Insights
    var timingInsightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Timing Insights", subtitle: "Your best performance windows")

            HStack(spacing: 10) {
                TimingCard(title: "Best Time", value: "6:00 AM", subtitle: "Most completions", icon: "sunrise.fill", color: .orange)
                TimingCard(title: "Hardest Habit", value: habitStore.habits.first?.name ?? "—", subtitle: "Most skipped", icon: "xmark.circle.fill", color: ForgeColor.error)
            }
        }
        .padding(ForgeSpacing.md)
        .forgeCard()
        .padding(.horizontal, ForgeSpacing.md)
    }

    // MARK: - Helpers
    private func barColor(_ rate: Double) -> LinearGradient {
        if rate >= 0.8 {
            return ForgeColor.greenGradient
        } else if rate >= 0.5 {
            return ForgeColor.accentGradient
        } else {
            return LinearGradient(colors: [.orange, .red.opacity(0.7)], startPoint: .bottom, endPoint: .top)
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000) }
        return "\(n)"
    }

    private func disciplineLabel(_ score: Int) -> String {
        switch score {
        case 800...: return "Elite"
        case 600...: return "Strong"
        case 400...: return "Building"
        default: return "Starting"
        }
    }

    private func consistencyLabel(_ score: Int) -> String {
        switch score {
        case 90...: return "Legendary"
        case 75...: return "Excellent"
        case 60...: return "Good"
        default: return "Improving"
        }
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textSecondary)
                .tracking(1)
            Text(trend)
                .font(ForgeTypography.labelXS)
                .foregroundColor(color.opacity(0.7))
        }
        .padding(ForgeSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(color.opacity(0.15), lineWidth: 1))
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(ForgeTypography.h3)
                .foregroundColor(.white)
            Text(subtitle)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
        }
    }
}

struct HabitPerformanceRow: View {
    let habit: Habit
    let store: HabitStore

    var completionRate: Double {
        let entries = store.entriesForHabit(habit.id, last: 30)
        guard !entries.isEmpty else { return 0 }
        let completed = entries.filter { $0.status == .completed }.count
        return Double(completed) / Double(entries.count)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: habit.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(habit.color)
                    .frame(width: 20)
                Text(habit.name)
                    .font(ForgeTypography.labelM)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(completionRate >= 0.8 ? ForgeColor.success : ForgeColor.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(ForgeColor.border).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [habit.color, habit.color.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * completionRate, height: 4)
                        .animation(.spring(response: 0.6), value: completionRate)
                }
            }
            .frame(height: 4)
        }
    }
}

struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let target: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textSecondary)
                Spacer()
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Goal: \(target)")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(ForgeColor.border).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: min(geo.size.width * progress, geo.size.width), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(ForgeSpacing.md)
        .frame(maxWidth: .infinity)
        .background(ForgeColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

struct TimingCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(ForgeTypography.h3)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textSecondary)
            Text(subtitle)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
        }
        .padding(ForgeSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ForgeColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
    }
}
