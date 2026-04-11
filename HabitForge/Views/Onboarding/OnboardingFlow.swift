import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @EnvironmentObject var notificationManager: NotificationManager
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var selectedGoals: Set<UserGoal> = []
    @State private var selectedEmoji = "🔥"
    @State private var wakeUpTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date()
    @State private var sleepTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    @State private var isAnimating = false

    let totalSteps = 4

    var body: some View {
        ZStack {
            ForgeColor.background.ignoresSafeArea()

            // Animated background orbs
            GeometryReader { geo in
                Circle()
                    .fill(ForgeColor.accent.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: isAnimating ? 100 : 50, y: isAnimating ? -50 : 50)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)

                Circle()
                    .fill(Color(hex: "#EF4444")?.opacity(0.08) ?? Color.red.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .offset(x: geo.size.width - 150, y: geo.size.height - 200)
            }
            .onAppear { isAnimating = true }

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentStep ? ForgeColor.accent : ForgeColor.border)
                            .frame(width: i == currentStep ? 24 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Steps
                Group {
                    switch currentStep {
                    case 0: WelcomeStep()
                    case 1: GoalSelectionStep(selectedGoals: $selectedGoals)
                    case 2: PersonalizationStep(
                        userName: $userName,
                        selectedEmoji: $selectedEmoji,
                        wakeUpTime: $wakeUpTime,
                        sleepTime: $sleepTime
                    )
                    case 3: SuggestedHabitsStep(selectedGoals: selectedGoals)
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4), value: currentStep)
                .id(currentStep)

                Spacer()

                // Navigation
                VStack(spacing: 12) {
                    Button {
                        if currentStep < totalSteps - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            finishOnboarding()
                        }
                    } label: {
                        HStack {
                            Text(currentStep < totalSteps - 1 ? "Continue" : "Start Forging 🔥")
                                .font(ForgeTypography.h3)
                        }
                        .foregroundColor(ForgeColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(ForgeColor.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
                        .shadow(color: ForgeColor.accent.opacity(0.3), radius: 12)
                    }
                    .buttonStyle(.plain)
                    .pressEffect()

                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Text("Back")
                                .font(ForgeTypography.labelM)
                                .foregroundColor(ForgeColor.textTertiary)
                        }
                    } else {
                        Text("Your data stays on your device")
                            .font(ForgeTypography.labelXS)
                            .foregroundColor(ForgeColor.textTertiary)
                    }
                }
                .padding(ForgeSpacing.md)
                .padding(.bottom, 20)
            }
        }
    }

    private func finishOnboarding() {
        habitStore.userProfile.name = userName
        habitStore.userProfile.avatarEmoji = selectedEmoji
        habitStore.userProfile.wakeUpTime = wakeUpTime
        habitStore.userProfile.sleepTime = sleepTime
        habitStore.userProfile.goals = Array(selectedGoals)

        // Add suggested habits based on goals
        for goal in selectedGoals.prefix(2) {
            for habit in goal.suggestedHabits.prefix(2) {
                habitStore.addHabit(habit)
            }
        }

        habitStore.saveUserProfile()
        notificationManager.scheduleDailyCheckIn()
        notificationManager.scheduleMorningMotivation()

        UserDefaults.standard.set(Date(), forKey: "lastDailyCheckIn")

        ForgeHaptics.success()
        withAnimation { hasCompletedOnboarding = true }
    }
}

// MARK: - Step 1: Welcome
struct WelcomeStep: View {
    @State private var showContent = false

    var body: some View {
        VStack(spacing: ForgeSpacing.xl) {
            // Logo
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(ForgeColor.accentGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: ForgeColor.accent.opacity(0.4), radius: 20)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(ForgeColor.textPrimary)
                }
                .scaleEffect(showContent ? 1.0 : 0.7)
                .animation(.spring(response: 0.6).delay(0.1), value: showContent)

                VStack(spacing: 8) {
                    Text("FORGE")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(ForgeColor.textPrimary)
                        .tracking(4)

                    Text("Build discipline.\nForge your future.")
                        .font(ForgeTypography.h3)
                        .foregroundColor(ForgeColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.6).delay(0.2), value: showContent)
            }

            // Feature highlights
            VStack(spacing: 12) {
                OnboardingFeatureRow(icon: "🎮", title: "Gamified Discipline", subtitle: "Level up in real life through daily habits")
                OnboardingFeatureRow(icon: "⚡", title: "Points & Streaks", subtitle: "Stay motivated with rewards and achievements")
                OnboardingFeatureRow(icon: "⌚", title: "Apple Watch", subtitle: "Complete habits from your wrist")
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.spring(response: 0.6).delay(0.4), value: showContent)
        }
        .padding(.horizontal, ForgeSpacing.xl)
        .onAppear { showContent = true }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ForgeTypography.h4)
                    .foregroundColor(ForgeColor.textPrimary)
                Text(subtitle)
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
    }
}

// MARK: - Step 2: Goal Selection
struct GoalSelectionStep: View {
    @Binding var selectedGoals: Set<UserGoal>

    var body: some View {
        VStack(alignment: .leading, spacing: ForgeSpacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What are you building?")
                    .font(ForgeTypography.h1)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("Select your top goals. You can change these anytime.")
                    .font(ForgeTypography.bodyS)
                    .foregroundColor(ForgeColor.textSecondary)
            }
            .padding(.horizontal, ForgeSpacing.md)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(UserGoal.allCases, id: \.self) { goal in
                        GoalCard(goal: goal, isSelected: selectedGoals.contains(goal)) {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                            ForgeHaptics.light()
                        }
                    }
                }
                .padding(.horizontal, ForgeSpacing.md)
            }
        }
    }
}

struct GoalCard: View {
    let goal: UserGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(goal.icon)
                    .font(.system(size: 36))

                VStack(spacing: 4) {
                    Text(goal.displayName)
                        .font(ForgeTypography.h4)
                        .foregroundColor(isSelected ? .white : ForgeColor.textSecondary)
                        .multilineTextAlignment(.center)

                    Text(goal.description)
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : ForgeColor.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(ForgeSpacing.md)
            .frame(maxWidth: .infinity)
            .background(isSelected ? ForgeColor.accentGradient : ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: ForgeRadius.lg)
                    .stroke(isSelected ? ForgeColor.accent : ForgeColor.border, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Personalization
struct PersonalizationStep: View {
    @Binding var userName: String
    @Binding var selectedEmoji: String
    @Binding var wakeUpTime: Date
    @Binding var sleepTime: Date

    let emojis = ["🔥", "⚡", "💪", "🏆", "👑", "💎", "🦅", "🌟", "🎯", "🧠", "🚀", "🦁"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForgeSpacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Make it yours.")
                        .font(ForgeTypography.h1)
                        .foregroundColor(ForgeColor.textPrimary)
                    Text("Personalize your FORGE experience")
                        .font(ForgeTypography.bodyS)
                        .foregroundColor(ForgeColor.textSecondary)
                }

                // Name
                ForgeTextField(label: "YOUR NAME", placeholder: "What should we call you?", text: $userName)

                // Emoji
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR AVATAR")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                                ForgeHaptics.light()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 50, height: 50)
                                    .background(selectedEmoji == emoji ? ForgeColor.accent.opacity(0.2) : ForgeColor.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedEmoji == emoji ? ForgeColor.accent : ForgeColor.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Sleep schedule
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR SCHEDULE")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Wake Up", systemImage: "sunrise.fill")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(.orange)
                            DatePicker("", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Sleep", systemImage: "moon.stars.fill")
                                .font(ForgeTypography.labelXS)
                                .foregroundColor(.indigo)
                            DatePicker("", selection: $sleepTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(ForgeSpacing.md)
                        .background(ForgeColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                    }
                }
            }
            .padding(.horizontal, ForgeSpacing.md)
        }
    }
}

// MARK: - Step 4: Suggested Habits Preview
struct SuggestedHabitsStep: View {
    let selectedGoals: Set<UserGoal>

    var suggestedHabits: [Habit] {
        Array(selectedGoals).prefix(3).flatMap { $0.suggestedHabits.prefix(2) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ForgeSpacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your starter forge.")
                    .font(ForgeTypography.h1)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("We've prepared habits based on your goals.\nYou can customize everything after.")
                    .font(ForgeTypography.bodyS)
                    .foregroundColor(ForgeColor.textSecondary)
            }
            .padding(.horizontal, ForgeSpacing.md)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(suggestedHabits.prefix(6)) { habit in
                        SuggestedHabitRow(habit: habit)
                    }
                }
                .padding(.horizontal, ForgeSpacing.md)
            }

            Text("All habits will be added to your dashboard.")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, ForgeSpacing.md)
        }
    }
}

struct SuggestedHabitRow: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(habit.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: habit.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(habit.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(ForgeTypography.h4)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("\(habit.category.displayName) · +\(habit.rewardPoints) pts · \(habit.difficulty.displayName)")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(ForgeColor.success)
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
    }
}
