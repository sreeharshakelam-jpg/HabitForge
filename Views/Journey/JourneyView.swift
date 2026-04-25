import SwiftUI

// MARK: - Journey Root

struct JourneyView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            ForgeColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                JourneyHeader(selectedTab: $selectedTab)
                TabView(selection: $selectedTab) {
                    JourneyPathView().tag(0)
                    ChainCalendarView().tag(1)
                    AccountabilityView().tag(2)
                    FourLawsView().tag(3)
                    JourneyJournalView().tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Top Tab Header

private struct JourneyHeader: View {
    @Binding var selectedTab: Int
    private let tabs = ["Path", "Chain", "Partners", "4 Laws", "Journal"]
    private let icons = ["figure.walk", "link", "person.2.fill", "4.circle.fill", "book.fill"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("YOUR JOURNEY")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    Text("Atomic Path")
                        .font(ForgeTypography.h2)
                        .foregroundColor(ForgeColor.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, ForgeSpacing.md)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<tabs.count, id: \.self) { i in
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedTab = i }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: icons[i])
                                    .font(.system(size: 12, weight: .semibold))
                                Text(tabs[i])
                                    .font(ForgeTypography.labelS)
                            }
                            .foregroundColor(selectedTab == i ? .white : ForgeColor.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selectedTab == i ? ForgeColor.accent : ForgeColor.card)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ForgeSpacing.md)
            }
            .padding(.bottom, 12)

            Divider().opacity(0.3)
        }
    }
}

// MARK: - Journey Path View

struct JourneyPathView: View {
    @EnvironmentObject var habitStore: HabitStore

    private let pathLength = 20
    private var steps: Int { min(habitStore.journeySteps, pathLength * 10) }
    private var currentNode: Int { (steps / 2) % pathLength }
    private var cycleCount: Int { steps / (pathLength * 2) }

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                characterBanner
                pathGrid
                milestoneCard
                goalSuggestions
            }
            .padding(.horizontal, ForgeSpacing.md)
            .padding(.vertical, 16)
        }
    }

    // Character banner at top
    private var characterBanner: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ForgeColor.accentGradient)
                    .frame(width: 80, height: 80)
                Text(habitStore.userProfile.avatarEmoji)
                    .font(.system(size: 40))
            }
            .shadow(color: ForgeColor.accent.opacity(0.4), radius: 16)

            Text("\(habitStore.userProfile.rank.emoji) \(habitStore.userProfile.rank.displayName)")
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.accent)

            HStack(spacing: 16) {
                PathStat(icon: "figure.walk", color: .purple, label: "Steps", value: "\(steps)")
                PathStat(icon: "star.fill", color: .yellow, label: "Cycles", value: "\(cycleCount)")
                PathStat(icon: "flame.fill", color: .orange, label: "Streak", value: "\(habitStore.userProfile.currentStreak)d")
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.xl)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.xl).stroke(ForgeColor.accent.opacity(0.2), lineWidth: 1))
        )
    }

    // Winding grid path
    private var pathGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("JOURNEY PATH")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<pathLength, id: \.self) { i in
                    PathNode(
                        index: i,
                        isCurrent: i == currentNode,
                        isCompleted: i < currentNode || (cycleCount > 0 && i != currentNode),
                        isMilestone: (i + 1) % 5 == 0
                    )
                }
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.xl)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.xl).stroke(ForgeColor.border, lineWidth: 1))
        )
    }

    private var milestoneCard: some View {
        let nextMilestone = ((currentNode / 5) + 1) * 5
        let stepsToNext = (nextMilestone - currentNode) * 2
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("NEXT MILESTONE")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                Text("Node \(nextMilestone)")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.accent)
            }
            Text("Complete \(stepsToNext) more habit logs to reach the next checkpoint")
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(ForgeColor.surfaceElevated)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ForgeColor.accentGradient)
                        .frame(width: geo.size.width * Double(currentNode % 5) / 5.0)
                        .animation(.spring(response: 0.5), value: currentNode)
                }
            }
            .frame(height: 8)
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        )
    }

    @ViewBuilder
    private var goalSuggestions: some View {
        let flaggedHabits = habitStore.habits.filter { habitStore.shouldSuggestReduction(for: $0.id) }
        if !flaggedHabits.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("1% IMPROVEMENTS")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                }
                ForEach(flaggedHabits) { habit in
                    HStack(spacing: 10) {
                        Image(systemName: habit.icon)
                            .foregroundColor(habit.color)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(ForgeTypography.h4)
                                .foregroundColor(ForgeColor.textPrimary)
                            Text("Struggling consistently — consider reducing target by 20%")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.textSecondary)
                        }
                    }
                }
            }
            .padding(ForgeSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeRadius.lg)
                    .fill(Color(hex: "#1A1500") ?? ForgeColor.card)
                    .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
            )
        }
    }
}

private struct PathNode: View {
    let index: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let isMilestone: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: nodeSize, height: nodeSize)
                .overlay(Circle().stroke(borderColor, lineWidth: isCurrent ? 2 : 1))
                .shadow(color: isCurrent ? ForgeColor.accent.opacity(0.5) : .clear, radius: 8)

            if isCurrent {
                Text("🏃")
                    .font(.system(size: 16))
            } else if isMilestone {
                Image(systemName: isCompleted ? "star.fill" : "star")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isCompleted ? .yellow : ForgeColor.textTertiary)
            } else if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ForgeColor.success)
            } else {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(ForgeColor.textTertiary)
            }
        }
    }

    private var nodeSize: CGFloat { isCurrent ? 56 : isMilestone ? 44 : 38 }

    private var bgColor: Color {
        if isCurrent { return ForgeColor.accent.opacity(0.2) }
        if isCompleted { return ForgeColor.success.opacity(0.15) }
        return ForgeColor.surfaceElevated
    }

    private var borderColor: Color {
        if isCurrent { return ForgeColor.accent }
        if isCompleted { return ForgeColor.success.opacity(0.4) }
        return ForgeColor.border
    }
}

private struct PathStat: View {
    let icon: String; let color: Color; let label: String; let value: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            Text(value).font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(ForgeColor.textPrimary)
            Text(label).font(ForgeTypography.labelXS).foregroundColor(ForgeColor.textSecondary)
        }
    }
}

// MARK: - Don't Break The Chain

struct ChainCalendarView: View {
    @EnvironmentObject var habitStore: HabitStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private var last30Days: [(Date, ChainStatus)] {
        (0..<30).reversed().map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            let dayEntries = habitStore.entriesForDate(date)
            if dayEntries.isEmpty { return (date, .empty) }
            let completed = dayEntries.filter { $0.status == .completed }.count
            let partial = dayEntries.filter { $0.status == .partiallyCompleted }.count
            let total = dayEntries.filter { $0.status != .skipped }.count
            if total == 0 { return (date, .empty) }
            let score = Double(completed) + Double(partial) * 0.5
            let rate = score / Double(total)
            if rate >= 0.8 { return (date, .full) }
            if rate >= 0.4 { return (date, .partial) }
            return (date, .missed)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                chainStats
                calendarGrid
                chainLegend
                atomicQuote
            }
            .padding(.horizontal, ForgeSpacing.md)
            .padding(.vertical, 16)
        }
    }

    private var chainStats: some View {
        HStack(spacing: 0) {
            ChainStat(value: "\(habitStore.userProfile.currentStreak)", label: "Current", color: .orange)
            Divider().frame(height: 40)
            ChainStat(value: "\(habitStore.userProfile.longestStreak)", label: "Best", color: .yellow)
            Divider().frame(height: 40)
            ChainStat(value: "\(last30Days.filter { $0.1 == .full }.count)", label: "Perfect Days", color: ForgeColor.success)
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(ForgeColor.accent)
                Text("DON'T BREAK THE CHAIN")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
            }

            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { d in
                    Text(d)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(ForgeColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<last30Days.count, id: \.self) { i in
                    ChainDay(date: last30Days[i].0, status: last30Days[i].1)
                }
            }
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
    }

    private var chainLegend: some View {
        HStack(spacing: 16) {
            LegendDot(color: ForgeColor.success, label: "Full day")
            LegendDot(color: ForgeColor.warning, label: "Partial")
            LegendDot(color: ForgeColor.error.opacity(0.6), label: "Missed")
            LegendDot(color: ForgeColor.surfaceElevated, label: "No habits")
        }
        .padding(.horizontal, 4)
    }

    private var atomicQuote: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.system(size: 20))
                .foregroundColor(ForgeColor.accent.opacity(0.5))
            Text("You don't rise to the level of your goals. You fall to the level of your systems.")
                .font(ForgeTypography.labelS)
                .foregroundColor(ForgeColor.textSecondary)
                .multilineTextAlignment(.center)
            Text("— James Clear, Atomic Habits")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.15), lineWidth: 1))
    }
}

enum ChainStatus: Equatable { case full, partial, missed, empty }

private struct ChainDay: View {
    let date: Date
    let status: ChainStatus
    private var day: Int { Calendar.current.component(.day, from: date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isToday ? ForgeColor.accent : Color.clear, lineWidth: 1.5))
            VStack(spacing: 1) {
                if status == .full {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ForgeColor.success)
                } else if status == .partial {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 9))
                        .foregroundColor(ForgeColor.warning)
                } else if status == .missed {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ForgeColor.error.opacity(0.7))
                }
                Text("\(day)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isToday ? ForgeColor.accent : ForgeColor.textTertiary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var bgColor: Color {
        switch status {
        case .full: return ForgeColor.success.opacity(0.18)
        case .partial: return ForgeColor.warning.opacity(0.15)
        case .missed: return ForgeColor.error.opacity(0.1)
        case .empty: return ForgeColor.surfaceElevated
        }
    }
}

private struct ChainStat: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(color)
            Text(label).font(ForgeTypography.labelXS).foregroundColor(ForgeColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LegendDot: View {
    let color: Color; let label: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(ForgeTypography.labelXS).foregroundColor(ForgeColor.textTertiary)
        }
    }
}

// MARK: - Accountability Partners

// UIViewControllerRepresentable wrapper for UIActivityViewController
struct ForgeShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

struct AccountabilityView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var partners: [AccountabilityPartner] = AccountabilityStore.load()
    @State private var showAddPartner = false
    @State private var showShareSheet = false
    @State private var contractText = UserDefaults.standard.string(forKey: "habitContract") ?? ""
    @State private var editingContract = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                accountabilityHeader
                shareProgressButton
                partnersSection
                contractSection
            }
            .padding(.horizontal, ForgeSpacing.md)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showAddPartner) {
            AddPartnerView { partner in
                partners.append(partner)
                AccountabilityStore.save(partners)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ForgeShareSheet(activityItems: [buildShareText()])
        }
    }

    private func buildShareText() -> String {
        let p = habitStore.userProfile
        return "🔥 My FORGE habit progress:\n• \(p.currentStreak)-day streak 🔥\n• \(p.rank.displayName) (Level \(p.level))\n• \(habitStore.habits.count) active habits\n• \(p.totalPoints) total points ⭐\n\nForging better habits one day at a time! 💪"
    }

    private var shareProgressButton: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                Text("Share My Progress")
                    .font(ForgeTypography.labelM)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(ForgeSpacing.md)
            .background(ForgeColor.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
            .shadow(color: ForgeColor.accent.opacity(0.35), radius: 8)
        }
        .buttonStyle(.plain)
    }

    private var accountabilityHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(ForgeColor.accent.opacity(0.15)).frame(width: 56, height: 56)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(ForgeColor.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Accountability Partners")
                    .font(ForgeTypography.h3)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("A behavior is less likely to occur when someone is watching")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textSecondary)
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.2), lineWidth: 1))
        )
    }

    private var partnersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PARTNERS")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                Button {
                    showAddPartner = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(ForgeTypography.labelS)
                        .foregroundColor(ForgeColor.accent)
                }
                .buttonStyle(.plain)
            }

            if partners.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 32))
                            .foregroundColor(ForgeColor.textTertiary)
                        Text("Add an accountability partner")
                            .font(ForgeTypography.labelS)
                            .foregroundColor(ForgeColor.textSecondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(ForgeColor.card)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
            } else {
                ForEach(partners) { partner in
                    PartnerRow(partner: partner) {
                        partners.removeAll { $0.id == partner.id }
                        AccountabilityStore.save(partners)
                    }
                }
            }
        }
    }

    private var contractSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(ForgeColor.accent)
                Text("HABIT CONTRACT")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                Button(editingContract ? "Done" : "Edit") {
                    if editingContract {
                        UserDefaults.standard.set(contractText, forKey: "habitContract")
                    }
                    editingContract.toggle()
                }
                .font(ForgeTypography.labelS)
                .foregroundColor(ForgeColor.accent)
            }

            if editingContract {
                TextEditor(text: $contractText)
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(ForgeColor.textPrimary)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(ForgeColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text(contractText.isEmpty
                     ? "Write your habit commitment here. Making it explicit increases follow-through."
                     : contractText)
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(contractText.isEmpty ? ForgeColor.textTertiary : ForgeColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ForgeSpacing.md)
                    .background(ForgeColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
    }
}

struct AccountabilityPartner: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var commitment: String
    var addedDate: Date
    init(id: UUID = UUID(), name: String, emoji: String = "🤝", commitment: String = "", addedDate: Date = Date()) {
        self.id = id; self.name = name; self.emoji = emoji
        self.commitment = commitment; self.addedDate = addedDate
    }
}

enum AccountabilityStore {
    private static let key = "accountabilityPartners"
    static func load() -> [AccountabilityPartner] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([AccountabilityPartner].self, from: data)
        else { return [] }
        return decoded
    }
    static func save(_ partners: [AccountabilityPartner]) {
        if let data = try? JSONEncoder().encode(partners) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

private struct PartnerRow: View {
    let partner: AccountabilityPartner
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(ForgeColor.accent.opacity(0.12)).frame(width: 44, height: 44)
                Text(partner.emoji).font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(partner.name)
                    .font(ForgeTypography.h4)
                    .foregroundColor(ForgeColor.textPrimary)
                if !partner.commitment.isEmpty {
                    Text(partner.commitment)
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(role: .destructive) { onDelete() } label: {
                Image(systemName: "trash").font(.system(size: 14)).foregroundColor(ForgeColor.error.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
    }
}

private struct AddPartnerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var commitment = ""
    @State private var selectedEmoji = "🤝"
    let onAdd: (AccountabilityPartner) -> Void
    private let emojis = ["🤝", "💪", "👊", "🔥", "⚡", "🦁", "🏆", "🎯"]

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        ForEach(emojis, id: \.self) { e in
                            Button {
                                selectedEmoji = e
                            } label: {
                                Text(e).font(.system(size: 28))
                                    .padding(8)
                                    .background(selectedEmoji == e ? ForgeColor.accent.opacity(0.2) : ForgeColor.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    PartnerTextField(placeholder: "Partner name", text: $name)
                    PartnerTextField(placeholder: "Their commitment (optional)", text: $commitment)
                    Spacer()
                }
                .padding(ForgeSpacing.md)
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(ForgeColor.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.isEmpty else { return }
                        onAdd(AccountabilityPartner(name: name, emoji: selectedEmoji, commitment: commitment))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(ForgeColor.accent)
                }
            }
        }
    }
}

private struct PartnerTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .font(ForgeTypography.bodyM)
            .foregroundColor(ForgeColor.textPrimary)
            .padding(ForgeSpacing.md)
            .background(ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
            .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
    }
}

// MARK: - 4 Laws of Behaviour Change

struct FourLawsView: View {
    @EnvironmentObject var habitStore: HabitStore

    private let laws: [AtomicLaw] = [
        AtomicLaw(number: 1, lawName: "Make It Obvious", badVersion: "Invisible",
                  icon: "eye.fill", color: "#3B82F6",
                  description: "Use implementation intentions and environment design. Put your habit cues in plain sight.",
                  tips: ["Set your gym bag by the door", "Put your book on the pillow", "Use a habit scorecard"]),
        AtomicLaw(number: 2, lawName: "Make It Attractive", badVersion: "Unattractive",
                  icon: "heart.fill", color: "#EC4899",
                  description: "Use temptation bundling. Join a culture where your habit is normal.",
                  tips: ["Pair habits with things you love", "Focus on identity: 'I am a runner'", "Reframe hard habits as opportunities"]),
        AtomicLaw(number: 3, lawName: "Make It Easy", badVersion: "Difficult",
                  icon: "bolt.fill", color: "#10B981",
                  description: "Reduce friction. Use the two-minute rule. Prime your environment.",
                  tips: ["Reduce steps needed to start", "2-minute rule: scale down to 2 min", "Decrease friction for good habits"]),
        AtomicLaw(number: 4, lawName: "Make It Satisfying", badVersion: "Unsatisfying",
                  icon: "star.fill", color: "#F59E0B",
                  description: "Use immediate rewards. Track your habits. Never miss twice.",
                  tips: ["Track progress visually", "Reward yourself after completing", "Don't break the chain"])
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                fourLawsHeader
                ForEach(laws) { law in
                    LawCard(law: law)
                }
                identityCard
            }
            .padding(.horizontal, ForgeSpacing.md)
            .padding(.vertical, 16)
        }
    }

    private var fourLawsHeader: some View {
        VStack(spacing: 8) {
            Text("⚛️")
                .font(.system(size: 40))
            Text("The 4 Laws of Behaviour Change")
                .font(ForgeTypography.h3)
                .foregroundColor(ForgeColor.textPrimary)
                .multilineTextAlignment(.center)
            Text("Good habits = Obvious · Attractive · Easy · Satisfying")
                .font(ForgeTypography.labelS)
                .foregroundColor(ForgeColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.xl).stroke(ForgeColor.accent.opacity(0.2), lineWidth: 1))
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.fill.checkmark")
                    .foregroundColor(ForgeColor.accent)
                Text("IDENTITY FIRST")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
            }
            Text("Every action is a vote for the type of person you wish to become.")
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.textPrimary)
            Text("The goal is not to run a marathon. The goal is to become a runner.")
                .font(ForgeTypography.labelS)
                .foregroundColor(ForgeColor.textSecondary)
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(Color(hex: "#0D0A1A") ?? ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.3), lineWidth: 1))
        )
    }
}

struct AtomicLaw: Identifiable {
    let id = UUID()
    let number: Int
    let lawName: String
    let badVersion: String
    let icon: String
    let color: String
    let description: String
    let tips: [String]
    var accentColor: Color { Color(hex: color) ?? .purple }
}

private struct LawCard: View {
    let law: AtomicLaw
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) { expanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(law.accentColor.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: law.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(law.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("Law \(law.number)")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(law.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(law.accentColor.opacity(0.12))
                                .clipShape(Capsule())
                            Text("vs \(law.badVersion)")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.textTertiary)
                        }
                        Text(law.lawName)
                            .font(ForgeTypography.h4)
                            .foregroundColor(ForgeColor.textPrimary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ForgeColor.textTertiary)
                }
                .padding(ForgeSpacing.md)
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().opacity(0.3)
                VStack(alignment: .leading, spacing: 10) {
                    Text(law.description)
                        .font(ForgeTypography.bodyM)
                        .foregroundColor(ForgeColor.textSecondary)
                    ForEach(law.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(law.accentColor).frame(width: 5, height: 5).padding(.top, 5)
                            Text(tip)
                                .font(ForgeTypography.labelS)
                                .foregroundColor(ForgeColor.textPrimary)
                        }
                    }
                }
                .padding(ForgeSpacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(expanded ? law.accentColor.opacity(0.3) : ForgeColor.border, lineWidth: 1))
    }
}
