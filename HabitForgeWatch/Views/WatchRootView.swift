import SwiftUI
import WatchKit

// MARK: - Root

struct WatchRootView: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        NavigationStack {
            WatchDashboardView()
        }
    }
}

// MARK: - Dashboard

struct WatchDashboardView: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                WatchProgressRingView()
                WatchXPBarView()

                if store.allDoneToday {
                    WatchAllDoneView()
                } else {
                    WatchHabitListSection()
                }

                WatchStatsRowView()
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Virtue Forge")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.requestSync() }
    }
}

// MARK: - Progress Ring

struct WatchProgressRingView: View {
    @EnvironmentObject var store: WatchHabitStore
    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 7)
                .frame(width: 72, height: 72)

            // Progress
            Circle()
                .trim(from: 0, to: animated)
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: "#7C3AED") ?? .purple, Color(hex: "#3B82F6") ?? .blue, Color(hex: "#7C3AED") ?? .purple],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 72, height: 72)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animated)

            VStack(spacing: 0) {
                Text("\(Int(store.todayProgress * 100))%")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("\(store.currentStreak)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
        }
        .onAppear { animated = store.todayProgress }
        .onChange(of: store.todayProgress) { animated = $0 }
    }
}

// MARK: - XP Bar

struct WatchXPBarView: View {
    @EnvironmentObject var store: WatchHabitStore
    @State private var animated: Double = 0

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text("\(store.rankEmoji) Lv.\(store.level)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.purple)
                Spacer()
                Text("\(store.totalXP) XP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(colors: [Color(hex: "#7C3AED") ?? .purple, Color(hex: "#3B82F6") ?? .blue],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * animated)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animated)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 4)
        .onAppear { animated = store.xpProgress }
        .onChange(of: store.xpProgress) { animated = $0 }
    }
}

// MARK: - Habit List

struct WatchHabitListSection: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("UP NEXT")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(store.pendingCount) left")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            ForEach(store.pendingEntries.prefix(4)) { entry in
                if let habit = store.habits.first(where: { $0.id == entry.habitId }) {
                    WatchHabitRowView(habit: habit, entry: entry)
                }
            }
        }
    }
}

// MARK: - Habit Row

struct WatchHabitRowView: View {
    @EnvironmentObject var store: WatchHabitStore
    let habit: WatchHabit
    let entry: WatchEntry

    @State private var tapped = false

    private var accentColor: Color { Color(hex: habit.colorHex) ?? .purple }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { tapped = true }
            store.completeHabit(entry.habitId)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { tapped = false }
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: habit.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(habit.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    HStack(spacing: 3) {
                        if entry.snoozeCount > 0 {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        }
                        Text("+\(habit.rewardPoints)pts")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if store.justCompletedHabitId == entry.habitId {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(tapped ? accentColor.opacity(0.2) : Color.white.opacity(0.07))
            )
            .scaleEffect(tapped ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.snoozeHabit(entry.habitId)
            } label: {
                Label("Snooze (-5pts)", systemImage: "clock")
            }
            Button(role: .destructive) {
                store.skipHabit(entry.habitId)
            } label: {
                Label("Skip", systemImage: "minus.circle")
            }
        }
    }
}

// MARK: - Stats Row

struct WatchStatsRowView: View {
    @EnvironmentObject var store: WatchHabitStore

    var body: some View {
        HStack(spacing: 5) {
            WatchStatPill(icon: "flame.fill",  color: .orange, value: "\(store.currentStreak)d")
            WatchStatPill(icon: "bolt.fill",   color: .purple, value: "\(store.totalPoints)")
            WatchStatPill(icon: "crown.fill",  color: .yellow, value: "L\(store.level)")
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
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
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
    @EnvironmentObject var store: WatchHabitStore
    @State private var scale: CGFloat = 0.7

    var body: some View {
        VStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 32))
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { scale = 1.1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring()) { scale = 1.0 }
                    }
                }
            Text("All Done!")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("+\(store.completedEntries.reduce(0) { $0 + $1.pointsEarned }) pts earned")
                .font(.system(size: 11))
                .foregroundColor(.yellow)
            Text("Perfect day.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Color Helper

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.hasPrefix("#") ? String(s.dropFirst()) : s
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >>  8) & 0xFF) / 255,
            blue:  Double( v        & 0xFF) / 255
        )
    }
}
