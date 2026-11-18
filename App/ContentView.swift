import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var habitStore: HabitStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var selectedTab = 0
    @State private var showDailySummary = false
    @State private var showDailyCheckIn = false
    @State private var showReconciliation = false
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "dark"
    @AppStorage(ForgeThemeManager.storageKey) private var activeThemeId = "royal"

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
                AvatarHomeView()
                    .tag(0)
                    .tabItem {
                        Label("Home", systemImage: "figure.arms.open")
                    }

                NavigationView {
                    JourneyView()
                }
                .tag(1)
                .tabItem {
                    Label("Journey", systemImage: "figure.walk")
                }

                JournalTabView()
                    .tag(2)
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }

                ProfileView()
                    .tag(3)
                    .tabItem {
                        Label("Profile", systemImage: "hammer.circle.fill")
                    }
            }
            .accentColor(ForgeColor.accent)
        }
        .id(activeThemeId)
        .preferredColorScheme(preferredScheme)
        .background(ForgeColor.background)
        .onAppear {
            checkDailyCheckIn()
            showReconciliation = !habitStore.pendingReconciliationEntries.isEmpty
        }
        .onReceive(habitStore.$pendingReconciliationEntries) { entries in
            showReconciliation = !entries.isEmpty
        }
        .sheet(isPresented: $showReconciliation) {
            ReconciliationModal()
                .environmentObject(habitStore)
                .environmentObject(gamificationEngine)
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

// MARK: - Journal Tab (own tab; was buried inside Journey)
struct JournalTabView: View {
    var body: some View {
        ZStack {
            ForgeAuroraBackground()
            VStack(alignment: .leading, spacing: 2) {
                Text("REFLECT")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Text("Journal")
                    .font(ForgeTypography.h2)
                    .foregroundColor(ForgeColor.textPrimary)
                    .padding(.bottom, 8)
                JourneyJournalView()
            }
            .padding(.top, 16)
            .padding(.horizontal, ForgeSpacing.md)
        }
    }
}
