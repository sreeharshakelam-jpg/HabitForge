import SwiftUI

// MARK: - Yesterday's Reconciliation Modal

struct ReconciliationModal: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            ForgeColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ForgeColor.textTertiary.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        habitsList
                        if habitStore.pendingReconciliationEntries.count > 1 {
                            batchActions
                        }
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.bottom, 48)
                }
            }
        }
        .interactiveDismissDisabled(!habitStore.pendingReconciliationEntries.isEmpty)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ForgeColor.accent.opacity(0.12))
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(ForgeColor.accent.opacity(0.3), lineWidth: 1.5))
                Image(systemName: "clock.badge.questionmark.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(ForgeColor.accentGradient)
            }

            VStack(spacing: 8) {
                Text("Yesterday's Unfinished Business")
                    .font(ForgeTypography.h2)
                    .foregroundColor(ForgeColor.textPrimary)
                    .multilineTextAlignment(.center)

                let count = habitStore.pendingReconciliationEntries.count
                Text("You had \(count) unchecked habit\(count == 1 ? "" : "s") yesterday. Did you actually do \(count == 1 ? "it" : "them")?")
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(ForgeColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Habit Cards

    private var habitsList: some View {
        VStack(spacing: 12) {
            ForEach(habitStore.pendingReconciliationEntries) { item in
                ReconciliationHabitCard(
                    habit: item.habit,
                    onDid: {
                        habitStore.reconcileEntry(item.entry.id, asCompleted: true)
                        ForgeHaptics.success()
                    },
                    onMissed: {
                        habitStore.reconcileEntry(item.entry.id, asCompleted: false)
                        ForgeHaptics.impact(.medium)
                    }
                )
            }
        }
    }

    // MARK: - Batch Actions

    private var batchActions: some View {
        VStack(spacing: 12) {
            Divider().opacity(0.3)

            Text("OR RESOLVE ALL AT ONCE")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)

            Button {
                habitStore.reconcileAll(asCompleted: true)
                ForgeHaptics.success()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Yes, I Did All of Them")
                        .font(ForgeTypography.h4)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(ForgeSpacing.md)
                .background(ForgeColor.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                .shadow(color: ForgeColor.accent.opacity(0.3), radius: 8)
            }
            .buttonStyle(.plain)

            Button {
                habitStore.reconcileAll(asCompleted: false)
                ForgeHaptics.impact(.medium)
            } label: {
                Text("Mark All as Missed")
                    .font(ForgeTypography.labelM)
                    .foregroundColor(ForgeColor.error.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Individual Habit Card

private struct ReconciliationHabitCard: View {
    let habit: Habit
    let onDid: () -> Void
    let onMissed: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(habit.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(habit.color.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: habit.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(habit.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(ForgeTypography.h3)
                        .foregroundColor(ForgeColor.textPrimary)
                    HStack(spacing: 8) {
                        DifficultyPill(difficulty: habit.difficulty)
                        Text("+\(habit.rewardPoints) pts if done")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onMissed) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Missed It")
                            .font(ForgeTypography.labelM)
                    }
                    .foregroundColor(ForgeColor.error.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: ForgeRadius.md)
                            .fill(ForgeColor.error.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(ForgeColor.error.opacity(0.25), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                Button(action: onDid) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Yes, I Did It")
                            .font(ForgeTypography.labelM)
                    }
                    .foregroundColor(ForgeColor.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: ForgeRadius.md)
                            .fill(ForgeColor.success.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(ForgeColor.success.opacity(0.3), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
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

private struct DifficultyPill: View {
    let difficulty: HabitDifficulty
    var body: some View {
        Text(difficulty.displayName)
            .font(ForgeTypography.labelXS)
            .foregroundColor(difficulty.color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(difficulty.color.opacity(0.12))
            .clipShape(Capsule())
    }
}
