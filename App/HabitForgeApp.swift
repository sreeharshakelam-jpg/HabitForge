import SwiftUI
import UserNotifications

@main
struct HabitForgeApp: App {
    @StateObject private var habitStore = HabitStore()
    @StateObject private var gamificationEngine = GamificationEngine()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var watchConnectivity = WatchConnectivityManager()
    @StateObject private var coach = ClaudeCoachService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "dark"

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(habitStore)
                        .environmentObject(gamificationEngine)
                        .environmentObject(notificationManager)
                        .environmentObject(healthKitManager)
                        .environmentObject(watchConnectivity)
                        .environmentObject(coach)
                } else {
                    OnboardingFlow()
                        .environmentObject(habitStore)
                        .environmentObject(gamificationEngine)
                        .environmentObject(notificationManager)
                        .environmentObject(coach)
                }
            }
            .preferredColorScheme(colorSchemePreference == "dark" ? .dark : (colorSchemePreference == "light" ? .light : nil))
            .onAppear {
                setupApp()
            }
        }
    }

    private func setupApp() {
        // Must be set before requestPermission so the delegate receives the initial callbacks.
        UNUserNotificationCenter.current().delegate = notificationManager
        notificationManager.habitStore = habitStore
        notificationManager.requestPermission()
        notificationManager.registerNotificationCategories()
        habitStore.gamificationEngine = gamificationEngine
        habitStore.notificationManager = notificationManager
        watchConnectivity.habitStore = habitStore
        gamificationEngine.habitStore = habitStore
        coach.habitStore = habitStore

        // One-time migration for v1.0.1: reset stale discipline score that was
        // mistakenly initialized to 100 in the original v1.0 release.
        let migrationKey = "didMigrateDisciplineV101"
        if !UserDefaults.standard.bool(forKey: migrationKey) {
            habitStore.userProfile.disciplineScore = 0
            habitStore.saveUserProfile()
            UserDefaults.standard.set(true, forKey: migrationKey)
        }

        // Re-schedule all habit reminders on launch so alarms actually fire.
        notificationManager.scheduleAllHabitReminders(habits: habitStore.habits)

        setupDailyReset()
        setupAppearance()
    }

    private func setupDailyReset() {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 0
        components.minute = 1
        if let midnight = calendar.date(from: components) {
            let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight) ?? midnight
            let timeInterval = nextMidnight.timeIntervalSince(now)
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                habitStore.performDailyReset()
            }
        }
    }

    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
