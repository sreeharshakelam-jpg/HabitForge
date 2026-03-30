import Foundation
import SwiftUI
import WatchConnectivity

class WatchHabitStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var habits: [Habit] = []
    @Published var todayEntries: [HabitEntry] = []
    @Published var currentStreak: Int = 0
    @Published var totalPoints: Int = 0
    @Published var level: Int = 1
    @Published var todayProgress: Double = 0
    @Published var rank: String = "Novice"
    @Published var rankEmoji: String = "🌱"
    @Published var pendingCount: Int = 0
    @Published var disciplineScore: Int = 0
    @Published var isConnected = false

    private let decoder = JSONDecoder()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        loadCachedData()
    }

    // MARK: - WCSession
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            if self.isConnected {
                self.requestSync()
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.parsePayload(applicationContext) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.parsePayload(message) }
    }

    private func parsePayload(_ payload: [String: Any]) {
        if let habitsData = payload["habits"] as? Data,
           let decoded = try? decoder.decode([Habit].self, from: habitsData) {
            habits = decoded
        }
        if let entriesData = payload["todayEntries"] as? Data,
           let decoded = try? decoder.decode([HabitEntry].self, from: entriesData) {
            todayEntries = decoded
        }
        currentStreak = payload["currentStreak"] as? Int ?? currentStreak
        totalPoints = payload["totalPoints"] as? Int ?? totalPoints
        level = payload["level"] as? Int ?? level
        todayProgress = payload["completionRate"] as? Double ?? todayProgress
        rank = payload["rank"] as? String ?? rank
        rankEmoji = payload["rankEmoji"] as? String ?? rankEmoji
        disciplineScore = payload["disciplineScore"] as? Int ?? disciplineScore
        pendingCount = todayEntries.filter { $0.status == .pending }.count
        saveCache()
    }

    // MARK: - Actions
    func completeHabit(_ habitId: UUID) {
        sendMessage(["completeHabit": habitId.uuidString])
        // Optimistic update
        if let i = todayEntries.firstIndex(where: { $0.habitId == habitId }) {
            todayEntries[i].status = .completed
            todayProgress = Double(todayEntries.filter { $0.status == .completed }.count) / Double(todayEntries.count)
            pendingCount = todayEntries.filter { $0.status == .pending }.count
        }
        WKInterfaceDevice.current().play(.success)
    }

    func snoozeHabit(_ habitId: UUID) {
        sendMessage(["snoozeHabit": habitId.uuidString])
        if let i = todayEntries.firstIndex(where: { $0.habitId == habitId }) {
            todayEntries[i].status = .snoozed
        }
        WKInterfaceDevice.current().play(.retry)
    }

    func skipHabit(_ habitId: UUID) {
        sendMessage(["skipHabit": habitId.uuidString])
        if let i = todayEntries.firstIndex(where: { $0.habitId == habitId }) {
            todayEntries[i].status = .skipped
        }
    }

    private func requestSync() {
        sendMessage(["requestSync": true])
    }

    private func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    // MARK: - Cache
    private func saveCache() {
        let encoder = JSONEncoder()
        if let habitsData = try? encoder.encode(habits) {
            UserDefaults.standard.set(habitsData, forKey: "watch_habits")
        }
        if let entriesData = try? encoder.encode(todayEntries) {
            UserDefaults.standard.set(entriesData, forKey: "watch_entries")
        }
        UserDefaults.standard.set(currentStreak, forKey: "watch_streak")
        UserDefaults.standard.set(totalPoints, forKey: "watch_points")
        UserDefaults.standard.set(level, forKey: "watch_level")
    }

    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: "watch_habits"),
           let decoded = try? decoder.decode([Habit].self, from: data) {
            habits = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "watch_entries"),
           let decoded = try? decoder.decode([HabitEntry].self, from: data) {
            todayEntries = decoded
        }
        currentStreak = UserDefaults.standard.integer(forKey: "watch_streak")
        totalPoints = UserDefaults.standard.integer(forKey: "watch_points")
        level = UserDefaults.standard.integer(forKey: "watch_level")
        todayProgress = Double(todayEntries.filter { $0.status == .completed }.count) / Double(max(todayEntries.count, 1))
        pendingCount = todayEntries.filter { $0.status == .pending }.count
    }
}

// Shared models need to be available - import from shared or duplicate minimal versions
// In a real project, use a Swift Package for shared models
struct Habit: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var category: String
    var rewardPoints: Int
    var scheduledTime: Date?
    var difficulty: String
}

struct HabitEntry: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    let date: Date
    var status: String
    var completedAt: Date?
    var pointsEarned: Int
    var snoozeCount: Int
}
