import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var selectedTab = 0
    @State private var showDailySummary = false
    @State private var showDailyCheckIn = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                    .tabItem {
                        Label("Today", systemImage: "bolt.circle.fill")
                    }

                HabitsListView()
                    .tag(1)
                    .tabItem {
                        Label("Habits", systemImage: "list.star")
                    }

                CoachView()
                    .tag(2)
                    .tabItem {
                        Label("Coach", systemImage: "brain.head.profile")
                    }

                AnalyticsView()
                    .tag(3)
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.xaxis")
                    }

                ProfileView()
                    .tag(4)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }
            }
            .accentColor(ForgeColor.accent)
        }
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
