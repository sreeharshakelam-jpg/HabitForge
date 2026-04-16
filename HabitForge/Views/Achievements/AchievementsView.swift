import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedAchievement: Achievement? = nil

    var filteredAchievements: [Achievement] {
        let source = habitStore.achievements
        if let cat = selectedCategory {
            return source.filter { $0.category == cat }
        }
        return source
    }

    var unlockedCount: Int {
        habitStore.achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: ForgeSpacing.md) {
                        // Profile Hero
                        profileHeroSection

                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "All", isSelected: selectedCategory == nil) {
                                    selectedCategory = nil
                                }
                                ForEach(AchievementCategory.allCases, id: \.self) { cat in
                                    FilterChip(label: cat.displayName, isSelected: selectedCategory == cat) {
                                        selectedCategory = selectedCategory == cat ? nil : cat
                                    }
                                }
                            }
                            .padding(.horizontal, ForgeSpacing.md)
                        }

                        // Achievement grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(filteredAchievements.sorted { $0.isUnlocked && !$1.isUnlocked }) { achievement in
                                AchievementCard(achievement: achievement) {
                                    selectedAchievement = achievement
                                }
                            }
                        }
                        .padding(.horizontal, ForgeSpacing.md)

                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, ForgeSpacing.md)
                }
            }
            .navigationTitle("Virtue Forge")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedAchievement) { ach in
            AchievementDetailSheet(achievement: ach)
        }
    }

    var profileHeroSection: some View {
        VStack(spacing: ForgeSpacing.md) {
            HStack(alignment: .center, spacing: ForgeSpacing.lg) {
                // Avatar + Rank
                ZStack {
                    Circle()
                        .fill(ForgeColor.accentGradient)
                        .frame(width: 80, height: 80)
                    Text(habitStore.userProfile.avatarEmoji)
                        .font(.system(size: 36))
                }
                .shadow(color: ForgeColor.accent.opacity(0.3), radius: 12)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(habitStore.userProfile.rank.emoji)
                            .font(.system(size: 18))
                        Text(habitStore.userProfile.rank.displayName.uppercased())
                            .font(ForgeTypography.labelS)
                            .foregroundColor(ForgeColor.accentBright)
                            .tracking(2)
                    }

                    Text(habitStore.userProfile.name.isEmpty ? "Forger" : habitStore.userProfile.name)
                        .font(ForgeTypography.h2)
                        .foregroundColor(ForgeColor.textPrimary)

                    Text("Level \(habitStore.userProfile.level)")
                        .font(ForgeTypography.labelM)
                        .foregroundColor(ForgeColor.textSecondary)
                }

                Spacer()
            }

            // XP Bar
            XPBar(progress: habitStore.userProfile.levelProgress, level: habitStore.userProfile.level)

            // Stats row
            HStack(spacing: 10) {
                ScorePill(
                    label: "Streak",
                    value: "\(habitStore.userProfile.currentStreak)🔥",
                    color: .orange,
                    icon: "flame.fill"
                )
                ScorePill(
                    label: "Achievements",
                    value: "\(unlockedCount)/\(habitStore.achievements.count)",
                    color: ForgeColor.accent,
                    icon: "trophy.fill"
                )
                ScorePill(
                    label: "Total XP",
                    value: "\(habitStore.userProfile.totalXP)",
                    color: ForgeColor.success,
                    icon: "sparkles"
                )
            }
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.xl).stroke(ForgeColor.border, lineWidth: 1))
        .padding(.horizontal, ForgeSpacing.md)
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    let onTap: () -> Void
    @State private var isAnimating = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ?
                              achievement.rarity.color.opacity(0.2) :
                              ForgeColor.border.opacity(0.2))
                        .frame(width: 60, height: 60)

                    if achievement.isUnlocked {
                        Circle()
                            .stroke(achievement.rarity.color.opacity(0.3), lineWidth: 1)
                            .frame(width: 60, height: 60)
                    }

                    Text(achievement.icon)
                        .font(.system(size: 26))
                        .opacity(achievement.isUnlocked ? 1.0 : 0.3)
                        .grayscale(achievement.isUnlocked ? 0 : 1)
                }
                .shadow(color: achievement.isUnlocked ? achievement.rarity.glowColor : .clear, radius: 8)
                .scaleEffect(isAnimating && achievement.isUnlocked ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                // Info
                VStack(spacing: 4) {
                    Text(achievement.title)
                        .font(ForgeTypography.labelM)
                        .foregroundColor(achievement.isUnlocked ? .white : ForgeColor.textTertiary)
                        .multilineTextAlignment(.center)

                    // Rarity badge
                    Text(achievement.rarity.displayName.uppercased())
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(achievement.isUnlocked ? achievement.rarity.color : ForgeColor.textTertiary)
                        .tracking(1)
                }

                // Progress bar (for locked achievements)
                if !achievement.isUnlocked && achievement.progress > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(ForgeColor.border).frame(height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(achievement.rarity.color.opacity(0.6))
                                .frame(width: geo.size.width * achievement.progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                } else if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ForgeColor.success)
                }
            }
            .padding(ForgeSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: ForgeRadius.lg)
                    .fill(ForgeColor.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: ForgeRadius.lg)
                            .stroke(
                                achievement.isUnlocked ?
                                achievement.rarity.color.opacity(0.3) :
                                ForgeColor.border,
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: achievement.isUnlocked ? achievement.rarity.glowColor : .clear, radius: 6)
        }
        .buttonStyle(.plain)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let achievement: Achievement

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                VStack(spacing: ForgeSpacing.xl) {
                    // Big icon
                    ZStack {
                        Circle()
                            .fill(achievement.rarity.color.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Circle()
                            .stroke(achievement.rarity.color.opacity(0.3), lineWidth: 2)
                            .frame(width: 120, height: 120)
                        Text(achievement.icon)
                            .font(.system(size: 56))
                            .opacity(achievement.isUnlocked ? 1.0 : 0.3)
                            .grayscale(achievement.isUnlocked ? 0 : 1)
                    }
                    .shadow(color: achievement.rarity.glowColor, radius: 20)

                    VStack(spacing: 8) {
                        Text(achievement.rarity.displayName.uppercased())
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(achievement.rarity.color)
                            .tracking(3)

                        Text(achievement.title)
                            .font(ForgeTypography.h1)
                            .foregroundColor(ForgeColor.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(achievement.description)
                            .font(ForgeTypography.bodyM)
                            .foregroundColor(ForgeColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if achievement.isUnlocked, let date = achievement.unlockedAt {
                        VStack(spacing: 4) {
                            Text("UNLOCKED")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.success)
                                .tracking(2)
                            Text(date.shortDateString)
                                .font(ForgeTypography.h4)
                                .foregroundColor(ForgeColor.textPrimary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(ForgeColor.success.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    // Rewards
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("+\(achievement.xpReward) XP")
                                .font(ForgeTypography.h3)
                                .foregroundColor(ForgeColor.accent)
                            Text("XP Reward")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.textTertiary)
                        }
                        VStack(spacing: 4) {
                            Text("+\(achievement.pointsReward) pts")
                                .font(ForgeTypography.h3)
                                .foregroundColor(ForgeColor.warning)
                            Text("Points Reward")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(ForgeColor.textTertiary)
                        }
                    }
                    .padding(ForgeSpacing.md)
                    .background(ForgeColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))

                    Spacer()
                }
                .padding(ForgeSpacing.xl)
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(ForgeColor.accent)
                }
            }
        }
    }
}
