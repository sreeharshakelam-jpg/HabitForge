import SwiftUI

// MARK: - Quantitative Verification Panel

struct QuantitativeVerificationPanel: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss

    let habit: Habit
    let entry: HabitEntry

    @State private var actualValue: Double

    init(habit: Habit, entry: HabitEntry) {
        self.habit = habit
        self.entry = entry
        _actualValue = State(initialValue: habit.targetValue ?? 1.0)
    }

    private var target: Double { habit.targetValue ?? 1.0 }
    private var unit: String { habit.targetUnit ?? "units" }
    private var percentage: Int { min(Int((actualValue / target) * 100), 999) }

    private var completionColor: Color {
        switch percentage {
        case 100...: return ForgeColor.success
        case 80..<100: return ForgeColor.accent
        case 50..<80: return ForgeColor.warning
        default: return ForgeColor.error
        }
    }

    private var statusLabel: String {
        switch percentage {
        case 100...: return "Full Completion"
        case 80..<100: return "Almost There"
        case 50..<80: return "Partial"
        default: return "Below 50% — Low Credit"
        }
    }

    private var pointsPreview: Int {
        let base = habit.rewardPoints
        let pct = actualValue / target
        if pct >= 1.0 { return base }
        if pct >= 0.5 { return Int(Double(base) * pct) }
        if pct > 0 { return Int(Double(base) * pct * 0.5) }
        return 0
    }

    var body: some View {
        ZStack {
            ForgeColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                dragHandle

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        habitIdentity
                        percentageDisplay
                        sliderSection
                        presetButtons
                        actionButton
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Subviews

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(ForgeColor.textTertiary.opacity(0.4))
            .frame(width: 40, height: 4)
            .padding(.top, 14)
            .padding(.bottom, 20)
    }

    private var habitIdentity: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(habit.color.opacity(0.14))
                    .frame(width: 68, height: 68)
                    .overlay(Circle().stroke(habit.color.opacity(0.35), lineWidth: 1.5))
                Image(systemName: habit.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(habit.color)
            }
            Text(habit.name)
                .font(ForgeTypography.h2)
                .foregroundColor(ForgeColor.textPrimary)
            Text("Target: \(formatValue(target)) \(unit)")
                .font(ForgeTypography.labelS)
                .foregroundColor(ForgeColor.textSecondary)
        }
    }

    private var percentageDisplay: some View {
        VStack(spacing: 10) {
            Text("\(percentage)%")
                .font(.system(size: 68, weight: .black, design: .rounded))
                .foregroundColor(completionColor)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: percentage)

            HStack(spacing: 10) {
                Text(statusLabel)
                    .font(ForgeTypography.labelM)
                    .foregroundColor(completionColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(completionColor.opacity(0.12))
                    .clipShape(Capsule())

                if pointsPreview > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("+\(pointsPreview) pts")
                            .font(ForgeTypography.labelM)
                    }
                    .foregroundColor(ForgeColor.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ForgeColor.accent.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var sliderSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("0 \(unit)")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                Spacer()
                Text("\(formatValue(actualValue)) / \(formatValue(target)) \(unit)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(ForgeColor.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.2), value: actualValue)
                Spacer()
                Text("\(formatValue(target * 1.2)) \(unit)")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
            }

            Slider(
                value: $actualValue,
                in: 0...(target * 1.2),
                step: target > 20 ? 0.5 : (target > 5 ? 0.25 : 0.1)
            )
            .tint(completionColor)
            .onChange(of: actualValue) { _ in
                ForgeHaptics.impact(.light)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(ForgeColor.surfaceElevated)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(completionColor)
                        .frame(width: geo.size.width * min(1.0, actualValue / target))
                        .animation(.spring(response: 0.3), value: actualValue)
                }
            }
            .frame(height: 10)
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        )
    }

    private var presetButtons: some View {
        HStack(spacing: 8) {
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                let isActive = (actualValue / target) >= fraction - 0.01
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        actualValue = target * fraction
                    }
                    ForgeHaptics.impact(.light)
                } label: {
                    Text("\(Int(fraction * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(isActive ? .white : ForgeColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: ForgeRadius.md)
                                .fill(isActive ? completionColor : ForgeColor.card)
                                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(isActive ? completionColor : ForgeColor.border, lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionButton: some View {
        VStack(spacing: 12) {
            Button {
                habitStore.completeQuantitativeHabit(entry, actualValue: actualValue)
                ForgeHaptics.success()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: percentage >= 100 ? "checkmark.circle.fill" : "circle.righthalf.filled")
                        .font(.system(size: 16, weight: .bold))
                    Text(percentage >= 100
                         ? "Log Full Completion"
                         : "Log \(formatValue(actualValue)) \(unit) (\(percentage)%)")
                        .font(ForgeTypography.h4)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(ForgeSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ForgeRadius.lg)
                        .fill(completionColor)
                )
                .shadow(color: completionColor.opacity(0.3), radius: 8)
            }
            .buttonStyle(.plain)
            .disabled(actualValue <= 0)

            Button { dismiss() } label: {
                Text("Cancel")
                    .font(ForgeTypography.labelM)
                    .foregroundColor(ForgeColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }
}
