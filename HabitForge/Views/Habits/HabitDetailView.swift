import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss
    let habit: Habit
    let entry: HabitEntry
    @State private var showEditSheet = false
    @State private var animateRing = false
    @State private var showDeleteConfirm = false

    var streak: Int { habitStore.currentStreakForHabit(habit.id) }
    var last7: [HabitEntry] { habitStore.entriesForHabit(habit.id, last: 7) }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ForgeSpacing.lg) {
                        // Hero Section
                        habitHeroSection

                        // Quick Actions
                        if entry.status == .pending || entry.status == .snoozed {
                            quickActionsSection
                        }

                        // Stats Row
                        statsRow

                        // 7-Day History
                        weekHistorySection

                        // Habit Info
                        habitInfoSection
                    }
                    .padding(ForgeSpacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ForgeColor.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showEditSheet = true } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(ForgeColor.textSecondary)
                    }
                }
            }
        }
        .confirmationDialog("Delete Habit?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                habitStore.deleteHabit(habit)
                dismiss()
            }
        }
    }

    var habitHeroSection: some View {
        VStack(spacing: ForgeSpacing.md) {
            // Icon + Ring
            ZStack {
                ForgeProgressRing(
                    progress: entry.status == .completed ? 1.0 : 0.0,
                    lineWidth: 6,
                    size: 110,
                    gradient: ForgeColor.habitGradient(habit)
                )

                Circle()
                    .fill(habit.color.opacity(0.15))
                    .frame(width: 85, height: 85)

                Image(systemName: habit.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(habit.color)
            }
            .shadow(color: habit.color.opacity(0.3), radius: 16)
            .onAppear { withAnimation(.spring(response: 0.8)) { animateRing = true } }

            // Status
            Text(entry.status.displayName.uppercased())
                .font(ForgeTypography.labelS)
                .foregroundColor(entry.status.color)
                .tracking(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(entry.status.color.opacity(0.12))
                .clipShape(Capsule())

            // Points earned
            if entry.status == .completed {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(ForgeColor.accent)
                    Text("+\(entry.pointsEarned) points earned")
                        .font(ForgeTypography.h4)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ForgeSpacing.lg)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
    }

    var quickActionsSection: some View {
        VStack(spacing: 10) {
            // Complete
            Button {
                withAnimation {
                    habitStore.completeHabit(entry)
                    ForgeHaptics.success()
                }
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Complete Now (+\(habit.rewardPoints) pts)")
                        .font(ForgeTypography.h4)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(ForgeSpacing.md)
                .background(ForgeColor.greenGradient)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                .shadow(color: ForgeColor.success.opacity(0.3), radius: 8)
            }
            .buttonStyle(.plain)
            .pressEffect()

            HStack(spacing: 10) {
                if habit.snoozeAllowed {
                    Button {
                        habitStore.snoozeHabit(entry)
                        ForgeHaptics.impact(.rigid)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                            Text("Snooze (-pts)")
                        }
                        .font(ForgeTypography.labelM)
                        .foregroundColor(ForgeColor.warning)
                        .frame(maxWidth: .infinity)
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.warning.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.warning.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    habitStore.skipHabit(entry)
                    ForgeHaptics.light()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "minus.circle")
                        Text("Skip Today")
                    }
                    .font(ForgeTypography.labelM)
                    .foregroundColor(ForgeColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(ForgeSpacing.md)
                    .background(ForgeColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    var statsRow: some View {
        HStack(spacing: 10) {
            ScorePill(label: "Streak", value: "\(streak)", color: .orange, icon: "flame.fill")
            ScorePill(label: "Points", value: "\(habit.rewardPoints)", color: ForgeColor.accent, icon: "bolt.fill")
            ScorePill(label: "Difficulty", value: habit.difficulty.displayName, color: habit.difficulty.color, icon: habit.difficulty.icon)
        }
    }

    var weekHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAST 7 DAYS")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)

            HStack(spacing: 8) {
                ForEach(0..<7) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: -(6 - offset), to: Date())!
                    let dayEntry = last7.first { Calendar.current.isDate($0.date, inSameDayAs: date) }

                    VStack(spacing: 4) {
                        Text(date.dayName)
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(entryColor(dayEntry).opacity(0.15))
                                .frame(width: 38, height: 38)

                            Image(systemName: entryIcon(dayEntry))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(entryColor(dayEntry))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
    }

    var habitInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HABIT DETAILS")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)

            VStack(spacing: 1) {
                InfoRow(label: "Category", value: habit.category.displayName, icon: habit.category.icon)
                InfoRow(label: "Type", value: habit.type.displayName, icon: habit.type.icon)
                InfoRow(label: "Frequency", value: habit.frequency.displayName, icon: "calendar")
                if let time = habit.scheduledTime {
                    InfoRow(label: "Scheduled", value: time.timeString, icon: "clock.fill")
                }
                if let dur = habit.durationMinutes {
                    InfoRow(label: "Duration", value: "\(dur) min", icon: "timer")
                }
                InfoRow(label: "XP Reward", value: "+\(habit.xpReward) XP", icon: "sparkles")
                InfoRow(label: "Created", value: habit.createdAt.shortDateString, icon: "calendar.badge.plus")
            }
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
    }

    private func entryColor(_ entry: HabitEntry?) -> Color {
        guard let e = entry else { return ForgeColor.border }
        switch e.status {
        case .completed: return ForgeColor.success
        case .missed: return ForgeColor.error
        case .snoozed: return ForgeColor.warning
        case .skipped: return ForgeColor.textTertiary
        default: return ForgeColor.textTertiary
        }
    }

    private func entryIcon(_ entry: HabitEntry?) -> String {
        guard let e = entry else { return "minus" }
        return e.status.icon
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ForgeColor.textTertiary)
                .frame(width: 20)
            Text(label)
                .font(ForgeTypography.bodyM)
                .foregroundColor(ForgeColor.textSecondary)
            Spacer()
            Text(value)
                .font(ForgeTypography.h4)
                .foregroundColor(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        Divider().background(ForgeColor.borderSubtle)
    }
}
