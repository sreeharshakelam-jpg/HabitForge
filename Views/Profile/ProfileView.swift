import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showEditProfile = false
    @State private var showResetConfirm = false
    @State private var exportItems: [Any] = []
    @State private var showExportSheet = false
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
        .confirmationDialog("Reset All Progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete Everything & Start Fresh", role: .destructive) {
                habitStore.resetAllProgress()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all habits, entries, and resets your stats. This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            if !exportItems.isEmpty {
                ActivityShareView(items: exportItems)
            }
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
                    .foregroundColor(ForgeColor.textPrimary)
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
                    .foregroundColor(ForgeColor.textPrimary)
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
                ProfileStat(icon: "chart.bar.fill", color: ForgeColor.info, value: "\(habitStore.userProfile.totalDisciplinedDays)", label: "Disciplined Days")
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
                SettingsActionRow(icon: "square.and.arrow.up", color: .blue, title: "Export Data") {
                    exportData()
                }
                SettingsActionRow(icon: "arrow.counterclockwise", color: .red, title: "Reset Progress", destructive: true) {
                    showResetConfirm = true
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
                    .foregroundColor(ForgeColor.textPrimary)
                Text("Version 1.0.6")
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

    private func exportData() {
        struct ExportPayload: Encodable {
            let exportDate: Date
            let habits: [Habit]
            let entries: [HabitEntry]
            let userProfile: UserProfile
            let dailyReports: [DailyReport]
        }

        let payload = ExportPayload(
            exportDate: Date(),
            habits: habitStore.habits,
            entries: habitStore.allEntries,
            userProfile: habitStore.userProfile,
            dailyReports: habitStore.dailyReports
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let timestamp = Int(Date().timeIntervalSince1970)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("forge_export_\(timestamp).json")
        try? jsonString.write(to: url, atomically: true, encoding: .utf8)
        exportItems = [url]
        showExportSheet = true
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
                .foregroundColor(ForgeColor.textPrimary)
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
                    .foregroundColor(ForgeColor.textPrimary)
            }
            Text(title)
                .font(ForgeTypography.bodyM)
                .foregroundColor(ForgeColor.textPrimary)
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
                    .foregroundColor(ForgeColor.textPrimary)
            }
            Text(title)
                .font(ForgeTypography.bodyM)
                .foregroundColor(ForgeColor.textPrimary)
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
                        .foregroundColor(ForgeColor.textPrimary)
                }
                Text(title)
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(destructive ? ForgeColor.error : ForgeColor.textPrimary)
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

// MARK: - Premium Sheet (removed — FORGE is 100% free for everyone)
// The PremiumSheet struct has been removed. All features are free.

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
                .foregroundColor(ForgeColor.textPrimary)
                .padding(ForgeSpacing.md)
                .background(ForgeColor.card)
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(ForgeColor.border, lineWidth: 1))
        }
    }
}

// MARK: - Activity Share Sheet
struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
