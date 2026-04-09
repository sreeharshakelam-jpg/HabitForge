import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showEditProfile = false
    @State private var showPremiumSheet = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = true
    @AppStorage("colorSchemePreference") var colorSchemePreference = "dark"

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: ForgeSpacing.md) {
                        // Profile Header
                        profileHeaderSection

                        // Premium Banner — hidden until StoreKit IAP is implemented
                        // if !habitStore.userProfile.isPremium {
                        //     premiumBanner
                        // }

                        // Stats Overview
                        statsOverviewSection

                        // Settings Sections
                        settingsSection

                        // App Info
                        appInfoSection

                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, ForgeSpacing.md)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 20))
                            .foregroundColor(ForgeColor.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(habitStore)
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumSheet()
        }
    }

    var profileHeaderSection: some View {
        VStack(spacing: ForgeSpacing.md) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(ForgeColor.accentGradient)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text(habitStore.userProfile.avatarEmoji)
                            .font(.system(size: 42))
                    )
                    .shadow(color: ForgeColor.accent.opacity(0.3), radius: 12)

                // Level badge
                Text("L\(habitStore.userProfile.level)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(ForgeColor.accent))
                    .offset(x: 4, y: 4)
            }

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(habitStore.userProfile.rank.emoji)
                    Text(habitStore.userProfile.rank.displayName.uppercased())
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.accentBright)
                        .tracking(2)
                }
                Text(habitStore.userProfile.name.isEmpty ? "Add Your Name" : habitStore.userProfile.name)
                    .font(ForgeTypography.h2)
                    .foregroundColor(.white)
                Text("@\(habitStore.userProfile.username.isEmpty ? "forger" : habitStore.userProfile.username)")
                    .font(ForgeTypography.labelM)
                    .foregroundColor(ForgeColor.textTertiary)
            }

            // XP bar
            XPBar(progress: habitStore.userProfile.levelProgress, level: habitStore.userProfile.level)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(ForgeSpacing.lg)
        .background(ForgeColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.xl).stroke(ForgeColor.border, lineWidth: 1))
        .padding(.horizontal, ForgeSpacing.md)
    }

    var premiumBanner: some View {
        Button {
            showPremiumSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(ForgeColor.goldGradient).frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Premium")
                        .font(ForgeTypography.h4)
                        .foregroundColor(.white)
                    Text("Unlock advanced analytics, AI coaching & more")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ForgeColor.textTertiary)
            }
            .padding(ForgeSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeRadius.lg)
                    .fill(Color(hex: "#1A1400") ?? .black)
                    .overlay(
                        RoundedRectangle(cornerRadius: ForgeRadius.lg)
                            .stroke(ForgeColor.goldGradient, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ForgeSpacing.md)
    }

    var statsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALL-TIME STATS")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)
                .padding(.horizontal, ForgeSpacing.md)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ProfileStat(icon: "flame.fill", color: .orange, value: "\(habitStore.userProfile.currentStreak)", label: "Streak")
                ProfileStat(icon: "bolt.fill", color: ForgeColor.accent, value: "\(habitStore.userProfile.totalPoints)", label: "Points")
                ProfileStat(icon: "checkmark.circle.fill", color: ForgeColor.success, value: "\(habitStore.userProfile.totalHabitsCompleted)", label: "Done")
                ProfileStat(icon: "crown.fill", color: ForgeColor.warning, value: "\(habitStore.userProfile.perfectDays)", label: "Perfect")
                ProfileStat(icon: "sparkles", color: Color(hex: "#8B5CF6") ?? .purple, value: "\(habitStore.userProfile.totalXP) XP", label: "Total XP")
                ProfileStat(icon: "chart.bar.fill", color: ForgeColor.info, value: "\(habitStore.userProfile.disciplineScore)", label: "Discipline")
            }
            .padding(.horizontal, ForgeSpacing.md)
        }
    }

    var settingsSection: some View {
        VStack(spacing: 2) {
            SettingsGroup(title: "PREFERENCES") {
                SettingsRow(icon: "moon.fill", color: .indigo, title: "Appearance") {
                    Picker("", selection: $colorSchemePreference) {
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.menu)
                    .tint(ForgeColor.accent)
                }

                SettingsToggleRow(
                    icon: "bell.fill", color: .red, title: "Notifications",
                    value: $habitStore.userProfile.notificationsEnabled
                )

                SettingsToggleRow(
                    icon: "quote.bubble.fill", color: .teal, title: "Motivational Quotes",
                    value: $habitStore.userProfile.motivationalQuotes
                )

                SettingsToggleRow(
                    icon: "waveform", color: .orange, title: "Haptic Feedback",
                    value: $habitStore.userProfile.hapticEnabled
                )
            }

            // HEALTH section hidden — HealthKit disabled in v1.0

            SettingsGroup(title: "DATA") {
                SettingsActionRow(icon: "square.and.arrow.up", color: .blue, title: "Export Data") {}
                SettingsActionRow(icon: "arrow.counterclockwise", color: .orange, title: "Reset Progress", destructive: true) {
                    // Confirm before resetting
                }
            }
        }
        .padding(.horizontal, ForgeSpacing.md)
    }

    var appInfoSection: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Text("⚡ FORGE")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Version 1.0.0")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                Text("Build your discipline. Forge your future.")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(ForgeSpacing.lg)
        }
    }
}

// MARK: - Supporting Views
struct ProfileStat: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)
                .padding(.horizontal, 4)
                .padding(.top, 12)

            VStack(spacing: 1) {
                content
            }
            .background(ForgeColor.card)
            .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(ForgeTypography.bodyM)
                .foregroundColor(.white)
            Spacer()
            trailing
        }
        .padding(ForgeSpacing.md)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    @Binding var value: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(ForgeTypography.bodyM)
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $value)
                .tint(ForgeColor.accent)
                .labelsHidden()
        }
        .padding(ForgeSpacing.md)
    }
}

struct SettingsActionRow: View {
    let icon: String
    let color: Color
    let title: String
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(destructive ? ForgeColor.error : .white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ForgeColor.textTertiary)
            }
            .padding(ForgeSpacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Sheet
struct PremiumSheet: View {
    @Environment(\.dismiss) var dismiss

    let features = [
        ("Advanced Analytics", "chart.bar.xaxis.ascending.badge.clock", Color(hex: "#3B82F6") ?? .blue),
        ("AI Coaching", "brain.head.profile", Color(hex: "#8B5CF6") ?? .purple),
        ("Voice Check-Ins", "waveform.circle.fill", Color(hex: "#10B981") ?? .green),
        ("Exclusive Themes", "paintpalette.fill", Color(hex: "#F59E0B") ?? .yellow),
        ("Unlimited Habits", "infinity", Color(hex: "#EF4444") ?? .red),
        ("Friends & Challenges", "person.2.fill", Color(hex: "#EC4899") ?? .pink),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ForgeSpacing.lg) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(ForgeColor.goldGradient)
                                .shadow(color: ForgeColor.warning.opacity(0.4), radius: 12)

                            Text("FORGE Premium")
                                .font(ForgeTypography.displayM)
                                .foregroundColor(.white)

                            Text("Unlock your full potential")
                                .font(ForgeTypography.bodyM)
                                .foregroundColor(ForgeColor.textSecondary)
                        }
                        .padding(.top, ForgeSpacing.xl)

                        // Features
                        VStack(spacing: 10) {
                            ForEach(features, id: \.0) { feature in
                                HStack(spacing: 14) {
                                    Image(systemName: feature.1)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(feature.2)
                                        .frame(width: 30)
                                    Text(feature.0)
                                        .font(ForgeTypography.h4)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ForgeColor.success)
                                }
                                .padding(ForgeSpacing.md)
                                .background(ForgeColor.card)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                            }
                        }
                        .padding(.horizontal, ForgeSpacing.md)

                        // Pricing
                        VStack(spacing: 12) {
                            Button {
                                // Handle purchase
                                dismiss()
                            } label: {
                                VStack(spacing: 4) {
                                    Text("$9.99 / month")
                                        .font(ForgeTypography.h3)
                                        .foregroundColor(.white)
                                    Text("Cancel anytime")
                                        .font(ForgeTypography.labelXS)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(ForgeSpacing.md)
                                .background(ForgeColor.goldGradient)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                                .shadow(color: ForgeColor.warning.opacity(0.3), radius: 12)
                            }
                            .buttonStyle(.plain)
                            .pressEffect()

                            Button {
                                dismiss()
                            } label: {
                                VStack(spacing: 4) {
                                    Text("$79.99 / year")
                                        .font(ForgeTypography.h3)
                                        .foregroundColor(.white)
                                    Text("Save 33% · Most popular")
                                        .font(ForgeTypography.labelXS)
                                        .foregroundColor(ForgeColor.success)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(ForgeSpacing.md)
                                .background(ForgeColor.card)
                                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.lg))
                                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, ForgeSpacing.md)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(ForgeColor.textSecondary)
                }
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var selectedEmoji = "🔥"

    let emojis = ["🔥", "⚡", "💪", "🏆", "👑", "💎", "🦅", "🐉", "🌟", "⚔️", "🔱", "🎯", "🧠", "🌙", "☀️", "🚀", "🌊", "🦁"]

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ForgeSpacing.lg) {
                        // Avatar selector
                        VStack(spacing: 12) {
                            Text("CHOOSE AVATAR")
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

                        // Fields
                        ForgeTextField(label: "NAME", placeholder: "Your name", text: $name)
                        ForgeTextField(label: "USERNAME", placeholder: "your_username", text: $username)
                        ForgeTextField(label: "BIO", placeholder: "What are you building?", text: $bio)
                    }
                    .padding(ForgeSpacing.md)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ForgeColor.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        habitStore.userProfile.name = name
                        habitStore.userProfile.username = username
                        habitStore.userProfile.bio = bio
                        habitStore.userProfile.avatarEmoji = selectedEmoji
                        habitStore.saveUserProfile()
                        dismiss()
                    }
                    .font(ForgeTypography.h4)
                    .foregroundColor(ForgeColor.accent)
                }
            }
            .onAppear {
                name = habitStore.userProfile.name
                username = habitStore.userProfile.username
                bio = habitStore.userProfile.bio
                selectedEmoji = habitStore.userProfile.avatarEmoji
            }
        }
    }
}

struct ForgeTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .tracking(2)
            TextField(placeholder, text: $text)
                .font(ForgeTypography.bodyM)
                .foregroundColor(.white)
                .padding(ForgeSpacing.md)
                .background(ForgeColor.card)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(ForgeColor.border, lineWidth: 1))
        }
    }
}
