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
        .sheet(isPresented: $showEditSheet) {
            EditHabitView(habit: habit)
                .environmentObject(habitStore)
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
                        .foregroundColor(ForgeColor.textPrimary)
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
                .foregroundColor(ForgeColor.textPrimary)
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
                .foregroundColor(ForgeColor.textPrimary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        Divider().background(ForgeColor.borderSubtle)
    }
}

// MARK: - Edit Habit View
struct EditHabitView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss

    let habit: Habit

    @State private var name: String
    @State private var description: String
    @State private var selectedIcon: String
    @State private var selectedColorHex: String
    @State private var selectedCategory: HabitCategory
    @State private var selectedType: HabitType
    @State private var selectedFrequency: HabitFrequency
    @State private var hasScheduledTime: Bool
    @State private var scheduledTime: Date
    @State private var hasDuration: Bool
    @State private var durationMinutes: Int
    @State private var selectedDifficulty: HabitDifficulty
    @State private var customPoints: Double
    @State private var reminderMinutesBefore: Int
    @State private var snoozeAllowed: Bool

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _description = State(initialValue: habit.description)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColorHex = State(initialValue: habit.colorHex)
        _selectedCategory = State(initialValue: habit.category)
        _selectedType = State(initialValue: habit.type)
        _selectedFrequency = State(initialValue: habit.frequency)
        _hasScheduledTime = State(initialValue: habit.scheduledTime != nil)
        _scheduledTime = State(initialValue: habit.scheduledTime ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date())
        _hasDuration = State(initialValue: habit.durationMinutes != nil)
        _durationMinutes = State(initialValue: habit.durationMinutes ?? 30)
        _selectedDifficulty = State(initialValue: habit.difficulty)
        _customPoints = State(initialValue: Double(habit.rewardPoints))
        _reminderMinutesBefore = State(initialValue: habit.reminderMinutesBefore)
        _snoozeAllowed = State(initialValue: habit.snoozeAllowed)
    }

    private let icons = [
        "star.fill","flame.fill","bolt.fill","heart.fill","brain.head.profile",
        "figure.run","figure.strengthtraining.traditional","bed.double.fill",
        "book.fill","pencil","fork.knife","drop.fill","leaf.fill","moon.fill",
        "sun.max.fill","music.note","dumbbell.fill","bicycle","pills.fill","cross.fill"
    ]

    private let colors = [
        "#7C3AED","#4F46E5","#0EA5E9","#10B981","#F59E0B",
        "#EF4444","#EC4899","#F97316","#8B5CF6","#06B6D4"
    ]

    var isValid: Bool { name.count >= 2 }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: ForgeSpacing.lg) {
                        // Name & Description
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("BASICS")
                            fieldLabel("Habit Name")
                            TextField("e.g. Morning Run", text: $name)
                                .textFieldStyle()
                            fieldLabel("Description (optional)")
                            TextField("What does this habit involve?", text: $description)
                                .textFieldStyle()
                            fieldLabel("Category")
                            categoryPicker
                        }
                        .sectionCard()

                        // Icon & Color
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("APPEARANCE")
                            fieldLabel("Icon")
                            iconGrid
                            fieldLabel("Color")
                            colorRow
                        }
                        .sectionCard()

                        // Schedule
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("SCHEDULE")
                            fieldLabel("Frequency")
                            frequencyPicker
                            Toggle("Set a scheduled time", isOn: $hasScheduledTime)
                                .toggleStyle(ForgeToggleStyle())
                            if hasScheduledTime {
                                DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                                    .colorScheme(.dark)
                            }
                            Toggle("Set duration", isOn: $hasDuration)
                                .toggleStyle(ForgeToggleStyle())
                            if hasDuration {
                                Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 5...240, step: 5)
                                    .foregroundColor(ForgeColor.textPrimary)
                            }
                        }
                        .sectionCard()

                        // Points & Difficulty
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("REWARDS")
                            fieldLabel("Difficulty")
                            difficultyPicker
                            fieldLabel("Points Reward: \(Int(customPoints))")
                            Slider(value: $customPoints, in: 5...500, step: 5)
                                .tint(ForgeColor.accent)
                            HStack(spacing: 8) {
                                ForEach([10, 25, 50, 100, 200], id: \.self) { pts in
                                    Button { customPoints = Double(pts) } label: {
                                        Text("\(pts)")
                                            .font(ForgeTypography.labelXS)
                                            .foregroundColor(Int(customPoints) == pts ? .white : ForgeColor.textSecondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Int(customPoints) == pts ? ForgeColor.accent : ForgeColor.card)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .sectionCard()

                        // Reminders
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("REMINDERS")
                            fieldLabel("Remind me: \(reminderMinutesBefore) min before")
                            Slider(value: Binding(
                                get: { Double(reminderMinutesBefore) },
                                set: { reminderMinutesBefore = Int($0) }
                            ), in: 0...60, step: 5)
                            .tint(ForgeColor.accent)
                            Toggle("Allow snooze", isOn: $snoozeAllowed)
                                .toggleStyle(ForgeToggleStyle())
                        }
                        .sectionCard()
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.top, ForgeSpacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ForgeColor.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveEdits() }
                        .font(ForgeTypography.h4)
                        .foregroundColor(isValid ? ForgeColor.accent : ForgeColor.textTertiary)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func saveEdits() {
        var updated = habit
        updated.name = name
        updated.description = description
        updated.icon = selectedIcon
        updated.colorHex = selectedColorHex
        updated.category = selectedCategory
        updated.type = selectedType
        updated.frequency = selectedFrequency
        updated.scheduledTime = hasScheduledTime ? scheduledTime : nil
        updated.durationMinutes = hasDuration ? durationMinutes : nil
        updated.difficulty = selectedDifficulty
        updated.rewardPoints = Int(customPoints)
        updated.reminderMinutesBefore = reminderMinutesBefore
        updated.snoozeAllowed = snoozeAllowed
        habitStore.updateHabit(updated)
        ForgeHaptics.success()
        dismiss()
    }

    // MARK: - Sub-views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(ForgeTypography.labelXS)
            .foregroundColor(ForgeColor.textTertiary)
            .tracking(2)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(ForgeTypography.labelM)
            .foregroundColor(ForgeColor.textSecondary)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HabitCategory.allCases, id: \.self) { cat in
                    Button { selectedCategory = cat } label: {
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 11))
                            Text(cat.displayName)
                                .font(ForgeTypography.labelXS)
                        }
                        .foregroundColor(selectedCategory == cat ? .white : ForgeColor.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedCategory == cat ? ForgeColor.accent : ForgeColor.card)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
            ForEach(icons, id: \.self) { icon in
                Button { selectedIcon = icon } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? ForgeColor.accent).opacity(0.2) : ForgeColor.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? ForgeColor.accent) : ForgeColor.border, lineWidth: selectedIcon == icon ? 2 : 1)
                            )
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? ForgeColor.accent) : ForgeColor.textSecondary)
                    }
                    .frame(height: 50)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            ForEach(colors, id: \.self) { hex in
                Button { selectedColorHex = hex } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: hex) ?? .purple)
                            .frame(width: 32, height: 32)
                        if selectedColorHex == hex {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 38, height: 38)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var frequencyPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HabitFrequency.allCases, id: \.self) { freq in
                    Button { selectedFrequency = freq } label: {
                        Text(freq.displayName)
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(selectedFrequency == freq ? .white : ForgeColor.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFrequency == freq ? ForgeColor.accent : ForgeColor.card)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            ForEach(HabitDifficulty.allCases, id: \.self) { diff in
                Button { selectedDifficulty = diff } label: {
                    VStack(spacing: 2) {
                        Image(systemName: diff.icon)
                            .font(.system(size: 14))
                        Text(diff.displayName)
                            .font(ForgeTypography.labelXS)
                    }
                    .foregroundColor(selectedDifficulty == diff ? .white : ForgeColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedDifficulty == diff ? diff.color.opacity(0.3) : ForgeColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: ForgeRadius.md)
                            .stroke(selectedDifficulty == diff ? diff.color : ForgeColor.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - EditHabitView helpers
private extension View {
    func textFieldStyle() -> some View {
        self
            .font(ForgeTypography.bodyM)
            .foregroundColor(ForgeColor.textPrimary)
            .padding(ForgeSpacing.md)
            .background(ForgeColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(ForgeColor.border, lineWidth: 1))
    }

    func sectionCard() -> some View {
        self
            .padding(ForgeSpacing.md)
            .background(ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
    }
}

private struct ForgeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(ForgeTypography.bodyM)
                .foregroundColor(ForgeColor.textPrimary)
            Spacer()
            Toggle("", isOn: configuration.$isOn)
                .tint(ForgeColor.accent)
                .labelsHidden()
        }
    }
}
