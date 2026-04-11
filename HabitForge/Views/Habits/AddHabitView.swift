import SwiftUI

struct AddHabitView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColorHex = "#7C3AED"
    @State private var selectedCategory = HabitCategory.wellness
    @State private var selectedType = HabitType.completion
    @State private var selectedFrequency = HabitFrequency.daily
    @State private var hasScheduledTime = false
    @State private var scheduledTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var hasDuration = false
    @State private var durationMinutes = 30
    @State private var selectedDifficulty = HabitDifficulty.medium
    @State private var reminderMinutesBefore = 10
    @State private var snoozeAllowed = true
    @State private var hasTarget = false
    @State private var targetValue: Double = 10
    @State private var targetUnit = ""
    @State private var currentPage = 0

    private let totalPages = 3

    var isValid: Bool { name.count >= 2 }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i <= currentPage ? ForgeColor.accent : ForgeColor.border)
                                .frame(height: 3)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.top, 8)

                    // Pages
                    TabView(selection: $currentPage) {
                        BasicsPage(
                            name: $name,
                            description: $description,
                            selectedCategory: $selectedCategory,
                            selectedType: $selectedType
                        )
                        .tag(0)

                        SchedulePage(
                            selectedFrequency: $selectedFrequency,
                            hasScheduledTime: $hasScheduledTime,
                            scheduledTime: $scheduledTime,
                            hasDuration: $hasDuration,
                            durationMinutes: $durationMinutes,
                            hasTarget: $hasTarget,
                            targetValue: $targetValue,
                            targetUnit: $targetUnit,
                            selectedType: selectedType
                        )
                        .tag(1)

                        AppearancePage(
                            selectedIcon: $selectedIcon,
                            selectedColorHex: $selectedColorHex,
                            selectedDifficulty: $selectedDifficulty,
                            reminderMinutesBefore: $reminderMinutesBefore,
                            snoozeAllowed: $snoozeAllowed,
                            habitName: name
                        )
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Navigation buttons
                    HStack(spacing: 12) {
                        if currentPage > 0 {
                            Button {
                                withAnimation { currentPage -= 1 }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(ForgeTypography.h4)
                                .foregroundColor(ForgeColor.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(ForgeSpacing.md)
                                .background(ForgeColor.card)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                            }
                        }

                        Button {
                            if currentPage < totalPages - 1 {
                                withAnimation { currentPage += 1 }
                            } else {
                                saveHabit()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(currentPage < totalPages - 1 ? "Next" : "Create Habit")
                                    .font(ForgeTypography.h4)
                                if currentPage < totalPages - 1 {
                                    Image(systemName: "chevron.right")
                                } else {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .foregroundColor(ForgeColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(ForgeSpacing.md)
                            .background(isValid ? ForgeColor.accentGradient : LinearGradient(colors: [ForgeColor.border], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                        }
                        .disabled(!isValid && currentPage == 0)
                    }
                    .padding(ForgeSpacing.md)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ForgeColor.textSecondary)
                }
            }
        }
    }

    private func saveHabit() {
        let habit = Habit(
            name: name,
            description: description,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            category: selectedCategory,
            type: selectedType,
            frequency: selectedFrequency,
            scheduledTime: hasScheduledTime ? scheduledTime : nil,
            durationMinutes: hasDuration ? durationMinutes : nil,
            difficulty: selectedDifficulty,
            isActive: true,
            reminderMinutesBefore: reminderMinutesBefore,
            snoozeAllowed: snoozeAllowed,
            targetValue: hasTarget ? targetValue : nil,
            targetUnit: hasTarget ? targetUnit : nil
        )
        habitStore.addHabit(habit)
        ForgeHaptics.success()
        dismiss()
    }
}

// MARK: - Page 1: Basics
struct BasicsPage: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var selectedCategory: HabitCategory
    @Binding var selectedType: HabitType

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForgeSpacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What habit do you want to build?")
                        .font(ForgeTypography.h2)
                        .foregroundColor(ForgeColor.textPrimary)
                    Text("Be specific. The clearer the habit, the easier to track.")
                        .font(ForgeTypography.bodyS)
                        .foregroundColor(ForgeColor.textSecondary)
                }

                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("HABIT NAME")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    TextField("e.g. Morning Workout", text: $name)
                        .font(ForgeTypography.h3)
                        .foregroundColor(ForgeColor.textPrimary)
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: ForgeRadius.md)
                                .stroke(name.isEmpty ? ForgeColor.border : ForgeColor.accent.opacity(0.4), lineWidth: 1)
                        )
                }

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    Text("DESCRIPTION (OPTIONAL)")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    TextField("Why this habit matters to you...", text: $description, axis: .vertical)
                        .font(ForgeTypography.bodyM)
                        .foregroundColor(ForgeColor.textPrimary)
                        .lineLimit(3, reservesSpace: true)
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(ForgeColor.border, lineWidth: 1))
                }

                // Category
                VStack(alignment: .leading, spacing: 10) {
                    Text("CATEGORY")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            CategoryChip(category: category, isSelected: selectedCategory == category) {
                                selectedCategory = category
                                ForgeHaptics.light()
                            }
                        }
                    }
                }

                // Type
                VStack(alignment: .leading, spacing: 10) {
                    Text("HABIT TYPE")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    ForEach(HabitType.allCases, id: \.self) { type in
                        HabitTypeRow(type: type, isSelected: selectedType == type) {
                            selectedType = type
                            ForgeHaptics.light()
                        }
                    }
                }
            }
            .padding(ForgeSpacing.md)
        }
    }
}

struct CategoryChip: View {
    let category: HabitCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : category.color)
                Text(category.displayName)
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(isSelected ? .white : ForgeColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? category.color : ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ForgeRadius.md)
                    .stroke(isSelected ? category.color : ForgeColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct HabitTypeRow: View {
    let type: HabitType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? ForgeColor.accent : ForgeColor.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(ForgeTypography.h4)
                        .foregroundColor(isSelected ? .white : ForgeColor.textSecondary)
                    Text(type.description)
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ForgeColor.accent)
                }
            }
            .padding(ForgeSpacing.md)
            .background(ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ForgeRadius.md)
                    .stroke(isSelected ? ForgeColor.accent.opacity(0.4) : ForgeColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page 2: Schedule
struct SchedulePage: View {
    @Binding var selectedFrequency: HabitFrequency
    @Binding var hasScheduledTime: Bool
    @Binding var scheduledTime: Date
    @Binding var hasDuration: Bool
    @Binding var durationMinutes: Int
    @Binding var hasTarget: Bool
    @Binding var targetValue: Double
    @Binding var targetUnit: String
    let selectedType: HabitType

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForgeSpacing.lg) {
                Text("When & How Often?")
                    .font(ForgeTypography.h2)
                    .foregroundColor(ForgeColor.textPrimary)

                // Frequency
                VStack(alignment: .leading, spacing: 10) {
                    Text("FREQUENCY")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)

                    ForEach([FrequencyType.daily, .weekdays, .weekends], id: \.self) { type in
                        let freq: HabitFrequency = type == .daily ? .daily : (type == .weekdays ? .weekdays : .weekends)
                        Button {
                            selectedFrequency = freq
                            ForgeHaptics.light()
                        } label: {
                            HStack {
                                Text(freq.displayName)
                                    .font(ForgeTypography.h4)
                                    .foregroundColor(selectedFrequency.type == type ? .white : ForgeColor.textSecondary)
                                Spacer()
                                if selectedFrequency.type == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ForgeColor.accent)
                                }
                            }
                            .padding(ForgeSpacing.md)
                            .background(ForgeColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(selectedFrequency.type == type ? ForgeColor.accent.opacity(0.4) : ForgeColor.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Scheduled Time
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $hasScheduledTime) {
                        Text("SCHEDULED TIME")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                            .tracking(2)
                    }
                    .tint(ForgeColor.accent)

                    if hasScheduledTime {
                        DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .colorScheme(.dark)
                            .frame(maxHeight: 120)
                            .clipped()
                    }
                }
                .padding(ForgeSpacing.md)
                .background(ForgeColor.card)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))

                // Duration (for duration-type habits)
                if selectedType == .duration {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DURATION")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                            .tracking(2)

                        HStack {
                            Text("\(durationMinutes) minutes")
                                .font(ForgeTypography.h3)
                                .foregroundColor(ForgeColor.textPrimary)
                            Spacer()
                        }
                        Slider(value: Binding(
                            get: { Double(durationMinutes) },
                            set: { durationMinutes = Int($0) }
                        ), in: 5...120, step: 5)
                        .tint(ForgeColor.accent)
                    }
                    .padding(ForgeSpacing.md)
                    .background(ForgeColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                }

                // Target (for quantity habits)
                if selectedType == .quantity {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DAILY TARGET")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                            .tracking(2)

                        HStack {
                            Text("\(Int(targetValue))")
                                .font(ForgeTypography.h2)
                                .foregroundColor(ForgeColor.textPrimary)
                            TextField("unit (e.g. glasses, km)", text: $targetUnit)
                                .font(ForgeTypography.bodyM)
                                .foregroundColor(ForgeColor.textSecondary)
                        }
                        Slider(value: $targetValue, in: 1...100, step: 1)
                            .tint(ForgeColor.accent)
                    }
                    .padding(ForgeSpacing.md)
                    .background(ForgeColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                }
            }
            .padding(ForgeSpacing.md)
        }
    }
}

// MARK: - Page 3: Appearance & Rewards
struct AppearancePage: View {
    @Binding var selectedIcon: String
    @Binding var selectedColorHex: String
    @Binding var selectedDifficulty: HabitDifficulty
    @Binding var reminderMinutesBefore: Int
    @Binding var snoozeAllowed: Bool
    let habitName: String

    let icons = ["star.fill", "heart.fill", "flame.fill", "bolt.fill", "moon.stars.fill",
                 "sun.max.fill", "drop.fill", "leaf.fill", "book.fill", "dumbbell.fill",
                 "figure.walk", "fork.knife", "brain.head.profile", "music.note",
                 "pencil", "paintbrush.fill", "trophy.fill", "crown.fill",
                 "timer", "clock.fill", "bed.double.fill", "briefcase.fill"]

    let colors = ["#7C3AED", "#EF4444", "#10B981", "#F59E0B", "#3B82F6",
                  "#EC4899", "#F97316", "#14B8A6", "#8B5CF6", "#22C55E",
                  "#6366F1", "#D97706", "#059669", "#DB2777", "#2563EB"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForgeSpacing.lg) {
                Text("Make it yours.")
                    .font(ForgeTypography.h2)
                    .foregroundColor(ForgeColor.textPrimary)

                // Preview Card
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill((Color(hex: selectedColorHex) ?? .purple).opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: selectedIcon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color(hex: selectedColorHex) ?? .purple)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(habitName.isEmpty ? "Your Habit" : habitName)
                            .font(ForgeTypography.h4)
                            .foregroundColor(ForgeColor.textPrimary)
                        Text("+\(selectedDifficulty.defaultPoints) points · \(selectedDifficulty.displayName)")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(ForgeSpacing.md)
                .background(ForgeColor.card)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))

                // Icons
                VStack(alignment: .leading, spacing: 10) {
                    Text("ICON")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                ForgeHaptics.light()
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(selectedIcon == icon ? Color(hex: selectedColorHex) ?? .purple : ForgeColor.textSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? .purple).opacity(0.15) : ForgeColor.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Colors
                VStack(alignment: .leading, spacing: 10) {
                    Text("COLOR")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(colors, id: \.self) { colorHex in
                            Button {
                                selectedColorHex = colorHex
                                ForgeHaptics.light()
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .purple)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle().stroke(.white, lineWidth: selectedColorHex == colorHex ? 2.5 : 0)
                                    )
                                    .scaleEffect(selectedColorHex == colorHex ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.2), value: selectedColorHex)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Difficulty
                VStack(alignment: .leading, spacing: 10) {
                    Text("DIFFICULTY & REWARD")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    HStack(spacing: 8) {
                        ForEach(HabitDifficulty.allCases, id: \.self) { diff in
                            Button {
                                selectedDifficulty = diff
                                ForgeHaptics.light()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: diff.icon)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedDifficulty == diff ? .white : diff.color)
                                    Text(diff.displayName)
                                        .font(ForgeTypography.labelXS)
                                        .foregroundColor(selectedDifficulty == diff ? .white : ForgeColor.textSecondary)
                                    Text("+\(diff.defaultPoints)")
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundColor(selectedDifficulty == diff ? .white.opacity(0.8) : ForgeColor.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedDifficulty == diff ? diff.color : ForgeColor.card)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Reminders
                VStack(alignment: .leading, spacing: 10) {
                    Text("REMINDER")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    Stepper("Remind \(reminderMinutesBefore) min before", value: $reminderMinutesBefore, in: 0...60, step: 5)
                        .font(ForgeTypography.bodyM)
                        .foregroundColor(ForgeColor.textPrimary)
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))

                    Toggle(isOn: $snoozeAllowed) {
                        VStack(alignment: .leading) {
                            Text("Allow Snooze")
                                .font(ForgeTypography.h4)
                                .foregroundColor(ForgeColor.textPrimary)
                            Text("Snoozing will reduce your points earned")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.textSecondary)
                        }
                    }
                    .tint(ForgeColor.accent)
                    .padding(ForgeSpacing.md)
                    .background(ForgeColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                }
            }
            .padding(ForgeSpacing.md)
        }
    }
}
