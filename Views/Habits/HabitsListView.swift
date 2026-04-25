import SwiftUI

struct HabitsListView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var showAddHabit = false
    @State private var searchText = ""
    @State private var selectedCategory: HabitCategory? = nil
    @State private var editMode = EditMode.inactive

    var filteredHabits: [Habit] {
        habitStore.habits.filter { habit in
            let categoryMatch = selectedCategory == nil || habit.category == selectedCategory
            let searchMatch = searchText.isEmpty || habit.name.localizedCaseInsensitiveContains(searchText)
            return categoryMatch && searchMatch
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search + Filter
                    VStack(spacing: 10) {
                        // Search
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ForgeColor.textTertiary)
                            TextField("Search habits...", text: $searchText)
                                .foregroundColor(ForgeColor.textPrimary)
                                .font(ForgeTypography.bodyM)
                        }
                        .padding(12)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))

                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "All", isSelected: selectedCategory == nil) {
                                    selectedCategory = nil
                                }
                                ForEach(HabitCategory.allCases, id: \.self) { cat in
                                    FilterChip(label: cat.displayName, isSelected: selectedCategory == cat, color: cat.color) {
                                        selectedCategory = selectedCategory == cat ? nil : cat
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ForgeSpacing.md)
                    .padding(.bottom, 10)

                    if filteredHabits.isEmpty {
                        HabitsEmptyState(showAddHabit: $showAddHabit)
                    } else {
                        List {
                            ForEach(filteredHabits) { habit in
                                HabitListRow(habit: habit)
                                    .listRowBackground(ForgeColor.background)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in
                                    habitStore.deleteHabit(filteredHabits[i])
                                }
                            }
                            .onMove(perform: habitStore.reorderHabits)
                        }
                        .listStyle(.plain)
                        .environment(\.editMode, $editMode)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("My Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation {
                                editMode = editMode == .inactive ? .active : .inactive
                            }
                        } label: {
                            Text(editMode == .inactive ? "Edit" : "Done")
                                .font(ForgeTypography.labelM)
                                .foregroundColor(ForgeColor.accent)
                        }

                        Button {
                            showAddHabit = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(ForgeColor.accentGradient)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddHabit) {
            AddHabitView()
                .environmentObject(habitStore)
        }
    }
}

// MARK: - Habit List Row
struct HabitListRow: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.editMode) private var editMode
    let habit: Habit
    @State private var showDetail = false

    var todayEntry: HabitEntry? {
        habitStore.todayEntries.first { $0.habitId == habit.id }
    }

    var streak: Int { habitStore.currentStreakForHabit(habit.id) }

    var body: some View {
        HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(habit.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: habit.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(habit.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(ForgeTypography.h4)
                        .foregroundColor(ForgeColor.textPrimary)

                    HStack(spacing: 8) {
                        // Category
                        Text(habit.category.displayName)
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(habit.category.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(habit.category.color.opacity(0.1))
                            .clipShape(Capsule())

                        // Frequency
                        Text(habit.frequency.displayName)
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)

                        // Streak
                        if streak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("\(streak)")
                                    .font(ForgeTypography.labelXS)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Points
                    Text("+\(habit.rewardPoints)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(ForgeColor.accent)

                    // Today status
                    if let entry = todayEntry {
                        Image(systemName: entry.status.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(entry.status.color)
                    }
                }
            }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture {
            guard editMode?.wrappedValue != .active else { return }
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            HabitDetailView(
                habit: habit,
                entry: todayEntry ?? HabitEntry(
                    habitId: habit.id,
                    date: Calendar.current.startOfDay(for: Date()),
                    status: .pending,
                    scheduledTime: habit.scheduledTime
                )
            )
            .environmentObject(habitStore)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = ForgeColor.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(ForgeTypography.labelM)
                .foregroundColor(isSelected ? .white : ForgeColor.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : ForgeColor.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? color : ForgeColor.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct HabitsEmptyState: View {
    @Binding var showAddHabit: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("⚡")
                .font(.system(size: 64))
            VStack(spacing: 8) {
                Text("Build Your Forge")
                    .font(ForgeTypography.h1)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("Add your first habit and start building\nthe life you want.")
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(ForgeColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showAddHabit = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Habit")
                }
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.textPrimary)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(ForgeColor.accentGradient)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}
