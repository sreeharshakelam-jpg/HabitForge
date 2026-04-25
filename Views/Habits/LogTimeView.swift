import SwiftUI

struct LogTimeView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss
    let habit: Habit
    let entry: HabitEntry

    @State private var selectedMinutes = 0

    private let presets = [10, 15, 20, 30, 45, 60, 90, 120]
    private var dailyTarget: Int { habit.dailyTargetMinutes }
    private var pct: Double {
        dailyTarget > 0 ? min(1.5, Double(selectedMinutes) / Double(dailyTarget)) : (selectedMinutes > 0 ? 1.0 : 0)
    }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        habitHeader
                        if selectedMinutes > 0 { completionRing }
                        presetGrid
                        customStepper
                        if dailyTarget > 0 { tierLegend }
                        if selectedMinutes > 0 { pointsPreviewRow }
                        logButton
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Log Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ForgeColor.textSecondary)
                }
            }
        }
    }

    // MARK: - Subviews

    private var habitHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(habit.color.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: habit.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(habit.color)
            }
            Text(habit.name)
                .font(ForgeTypography.h3)
                .foregroundColor(ForgeColor.textPrimary)
            if dailyTarget > 0 {
                Text("Daily target · \(dailyTarget) min")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.textSecondary)
            } else {
                Text("Log how long you did this habit")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.textSecondary)
            }
        }
    }

    private var completionRing: some View {
        ZStack {
            Circle()
                .stroke(ForgeColor.surfaceElevated, lineWidth: 10)
                .frame(width: 110, height: 110)
            Circle()
                .trim(from: 0, to: min(1, pct))
                .stroke(tierColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 110, height: 110)
                .animation(.spring(response: 0.5), value: pct)
            VStack(spacing: 2) {
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(tierColor)
                Text(tierLabel)
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(tierColor.opacity(0.8))
            }
        }
    }

    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK SELECT")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)
                .padding(.horizontal, 4)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(presets, id: \.self) { m in
                    Button {
                        withAnimation(.spring(response: 0.25)) { selectedMinutes = m }
                        ForgeHaptics.light()
                    } label: {
                        VStack(spacing: 2) {
                            Text(formatMin(m))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            if dailyTarget > 0 {
                                Text("\(Int(Double(m)/Double(dailyTarget)*100))%")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(selectedMinutes == m ? .white.opacity(0.8) : .secondary)
                            }
                        }
                        .foregroundColor(selectedMinutes == m ? .white : ForgeColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMinutes == m ? habit.color : ForgeColor.card)
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedMinutes == m ? habit.color : ForgeColor.border, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, ForgeSpacing.md)
    }

    private var customStepper: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CUSTOM")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)
                .padding(.horizontal, 4)
            HStack(spacing: 0) {
                Button {
                    if selectedMinutes >= 5 { selectedMinutes -= 5 }
                    ForgeHaptics.light()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(selectedMinutes > 0 ? ForgeColor.accent : ForgeColor.textTertiary)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text("\(selectedMinutes)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(ForgeColor.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.2), value: selectedMinutes)
                    Text("minutes")
                        .font(ForgeTypography.labelS)
                        .foregroundColor(ForgeColor.textSecondary)
                }
                Spacer()
                Button {
                    selectedMinutes += 5
                    ForgeHaptics.light()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(ForgeColor.accent)
                }
            }
            .padding(ForgeSpacing.md)
            .background(ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        }
        .padding(.horizontal, ForgeSpacing.md)
    }

    private var tierLegend: some View {
        HStack(spacing: 0) {
            TierPill(label: "Completed", threshold: "≥ 80%", color: ForgeColor.success,
                     isActive: pct >= 0.8 && selectedMinutes > 0)
            Rectangle().fill(ForgeColor.border).frame(width: 1, height: 44)
            TierPill(label: "Partial", threshold: "50–79%", color: ForgeColor.warning,
                     isActive: pct >= 0.5 && pct < 0.8 && selectedMinutes > 0)
            Rectangle().fill(ForgeColor.border).frame(width: 1, height: 44)
            TierPill(label: "Missed", threshold: "< 50%", color: ForgeColor.error,
                     isActive: pct < 0.5 && selectedMinutes > 0)
        }
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        .padding(.horizontal, ForgeSpacing.md)
    }

    private var pointsPreviewRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .foregroundColor(ForgeColor.accent)
            Text("You'll earn \(pointsPreview) pts · \(xpPreview) XP")
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.textPrimary)
            Spacer()
            Text(tierLabel)
                .font(ForgeTypography.labelS)
                .foregroundColor(tierColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(tierColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, ForgeSpacing.md)
    }

    private var logButton: some View {
        Button {
            guard selectedMinutes > 0 else { return }
            habitStore.logTime(entry, minutes: selectedMinutes)
            ForgeHaptics.success()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedMinutes > 0 ? "checkmark.circle.fill" : "clock")
                Text(selectedMinutes > 0 ? "Log \(formatMin(selectedMinutes))" : "Pick a duration first")
                    .font(ForgeTypography.h4)
            }
            .foregroundColor(selectedMinutes > 0 ? .white : ForgeColor.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(ForgeSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeRadius.xl)
                    .fill(selectedMinutes > 0 ? habit.color : ForgeColor.surfaceElevated)
            )
        }
        .disabled(selectedMinutes == 0)
        .padding(.horizontal, ForgeSpacing.md)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private var tierColor: Color {
        if pct >= 0.8 { return ForgeColor.success }
        if pct >= 0.5 { return ForgeColor.warning }
        return ForgeColor.error
    }

    private var tierLabel: String {
        if pct >= 0.8 { return "Completed" }
        if pct >= 0.5 { return "Partial" }
        return "Missed"
    }

    private var pointsPreview: Int {
        let m = pct >= 0.8 ? 1.0 : pct >= 0.5 ? 0.5 : 0.0
        return Int(Double(habit.rewardPoints) * m)
    }

    private var xpPreview: Int {
        let m = pct >= 0.8 ? 1.0 : pct >= 0.5 ? 0.5 : 0.0
        return Int(Double(habit.xpReward) * m)
    }

    private func formatMin(_ m: Int) -> String {
        if m < 60 { return "\(m)m" }
        let h = m / 60; let r = m % 60
        return r > 0 ? "\(h)h \(r)m" : "\(h)h"
    }
}

private struct TierPill: View {
    let label: String
    let threshold: String
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? color : color.opacity(0.2))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isActive ? color : ForgeColor.textTertiary)
            Text(threshold)
                .font(.system(size: 9))
                .foregroundColor(ForgeColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}
