import SwiftUI
import UserNotifications

@main
struct HabitForgeApp: App {
    @StateObject private var habitStore = HabitStore()
    @StateObject private var gamificationEngine = GamificationEngine()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var watchConnectivity = WatchConnectivityManager()
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
                } else {
                    OnboardingFlow()
                        .environmentObject(habitStore)
                        .environmentObject(gamificationEngine)
                        .environmentObject(notificationManager)
                }
            }
            .preferredColorScheme(colorSchemePreference == "dark" ? .dark : (colorSchemePreference == "light" ? .light : nil))
            .onAppear {
                setupApp()
            }
        }
    }

    private func setupApp() {
        notificationManager.requestPermission()
        habitStore.gamificationEngine = gamificationEngine
        watchConnectivity.habitStore = habitStore
        gamificationEngine.habitStore = habitStore
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
