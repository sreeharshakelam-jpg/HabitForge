import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var selectedTab = 0
    @State private var showDailySummary = false
    @State private var showDailyCheckIn = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "dark"

    private var preferredScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                CoachView()
                    .tag(0)
                    .tabItem {
                        Label("Mentor", systemImage: "brain.head.profile")
                    }

                DashboardView()
                    .tag(1)
                    .tabItem {
                        Label("Ritual", systemImage: "sunrise.circle.fill")
                    }

                HabitsListView()
                    .tag(2)
                    .tabItem {
                        Label("Virtues", systemImage: "sparkles")
                    }

                NavigationView {
                    JourneyView()
                }
                .tag(3)
                .tabItem {
                    Label("Journey", systemImage: "figure.walk")
                }

                ProfileView()
                    .tag(4)
                    .tabItem {
                        Label("Forge", systemImage: "hammer.circle.fill")
                    }
            }
            .accentColor(ForgeColor.accent)
        }
        .preferredColorScheme(preferredScheme)
        .background(ForgeColor.background)
        .onAppear {
            checkDailyCheckIn()
        }
        .sheet(isPresented: $showDailyCheckIn) {
            DailyCheckInView()
                .environmentObject(habitStore)
                .environmentObject(gamificationEngine)
        }
        .sheet(isPresented: $showDailySummary) {
            DailySummaryView()
                .environmentObject(habitStore)
                .environmentObject(gamificationEngine)
        }
        .onChange(of: habitStore.shouldShowDailySummary) { show in
            if show { showDailySummary = true }
        }
    }

    private func checkDailyCheckIn() {
        let lastCheckIn = UserDefaults.standard.object(forKey: "lastDailyCheckIn") as? Date
        let calendar = Calendar.current
        if lastCheckIn == nil || !calendar.isDateInToday(lastCheckIn!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showDailyCheckIn = true
            }
        }
    }
}
