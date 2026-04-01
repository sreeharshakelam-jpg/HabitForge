import SwiftUI
import WatchKit

// MARK: - Watch Root View
struct WatchRootView: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        NavigationStack {
            WatchDashboardView()
        }
    }
}

// MARK: - Watch Dashboard
struct WatchDashboardView: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Progress Ring + Score
                WatchProgressRing()

                // Pending habits
                if !pendingHabits.isEmpty {
                    VStack(spacing: 6) {
                        Text("UP NEXT")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)

                        ForEach(pendingHabits.prefix(3), id: \.id) { entry in
                            if let habit = store.habits.first(where: { $0.id == entry.habitId }) {
                                WatchHabitRow(habit: habit, entry: entry)
                            }
                        }
                    }
                } else {
                    WatchAllDoneView()
                }

                // Stats row
                WatchStatsRow()
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("FORGE")
        .navigationBarTitleDisplayMode(.inline)
    }

    var pendingHabits: [HabitEntry] {
        store.todayEntries.filter { $0.status == "pending" || $0.status == "snoozed" }
    }
}

// MARK: - Watch Progress Ring
struct WatchProgressRing: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 6)
                .frame(width: 70, height: 70)

            Circle()
                .trim(from: 0, to: store.todayProgress)
                .stroke(
                    AngularGradient(colors: [.purple, .blue], center: .center),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 70, height: 70)
                .animation(.spring(), value: store.todayProgress)

            VStack(spacing: 0) {
                Text("\(Int(store.todayProgress * 100))%")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: - Watch Habit Row
struct WatchHabitRow: View {
    @EnvironmentObject var store: WatchHabitStore
    let habit: Habit
    let entry: HabitEntry

    var body: some View {
        Button {
            store.completeHabit(entry.habitId)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: habit.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: habit.colorHex) ?? .purple)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 1) {
                    Text(habit.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("+\(habit.rewardPoints)pts")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Quick complete circle
                ZStack {
                    Circle()
                        .stroke(Color(hex: habit.colorHex)?.opacity(0.4) ?? Color.purple.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: habit.colorHex) ?? .purple)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.snoozeHabit(entry.habitId)
            } label: {
                Label("Snooze", systemImage: "clock")
            }
            Button(role: .destructive) {
                store.skipHabit(entry.habitId)
            } label: {
                Label("Skip", systemImage: "minus.circle")
            }
        }
    }
}

// MARK: - Watch Stats Row
struct WatchStatsRow: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        HStack(spacing: 6) {
            WatchStatPill(icon: "flame.fill", color: .orange, value: "\(store.currentStreak)")
            WatchStatPill(icon: "bolt.fill", color: .purple, value: "\(store.totalPoints)")
            WatchStatPill(icon: "crown.fill", color: .yellow, value: "L\(store.level)")
        }
    }
}

struct WatchStatPill: View {
    let icon: String
    let color: Color
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - All Done
struct WatchAllDoneView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 30))
            Text("All Done!")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Perfect day so far.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Color extension for Watch
extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.hasPrefix("#") ? String(s.dropFirst()) : s
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
