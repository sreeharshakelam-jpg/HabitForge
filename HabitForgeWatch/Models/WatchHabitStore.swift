import Foundation
import SwiftUI
import WatchConnectivity
import WatchKit

class WatchHabitStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var habits: [WatchHabit] = []
    @Published var todayEntries: [WatchEntry] = []
    @Published var currentStreak: Int = 0
    @Published var totalPoints: Int = 0
    @Published var level: Int = 1
    @Published var totalXP: Int = 0
    @Published var rank: String = "Novice"
    @Published var rankEmoji: String = "🌱"
    @Published var disciplineScore: Int = 0
    @Published var isConnected = false
    @Published var lastSyncDate: Date? = nil
    @Published var justCompletedHabitId: UUID? = nil

    private let decoder = JSONDecoder()

    var todayProgress: Double {
        guard !todayEntries.isEmpty else { return 0 }
        let done = todayEntries.filter { $0.status == "completed" }.count
        return Double(done) / Double(todayEntries.count)
    }

    var pendingEntries: [WatchEntry] {
        todayEntries.filter { $0.status == "pending" || $0.status == "snoozed" }
    }

    var completedEntries: [WatchEntry] {
        todayEntries.filter { $0.status == "completed" }
    }

    var pendingCount: Int { pendingEntries.count }
    var allDoneToday: Bool { !todayEntries.isEmpty && pendingEntries.isEmpty }

    var xpForNextLevel: Int { level * 100 }
    var xpProgress: Double {
        let base = (level - 1) * 100
        let cap = level * 100
        guard cap > base else { return 1 }
        return Double(totalXP - base) / Double(cap - base)
    }

    override init() {
        super.init()
        loadCachedData()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - WCSession Delegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = state == .activated
            if self.isConnected { self.requestSync() }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext ctx: [String: Any]) {
        DispatchQueue.main.async { self.parsePayload(ctx) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.parsePayload(message) }
    }

    private func parsePayload(_ payload: [String: Any]) {
        if let data = payload["habits"] as? Data,
           let decoded = try? decoder.decode([WatchHabit].self, from: data) {
            habits = decoded
        }
        if let data = payload["todayEntries"] as? Data,
           let decoded = try? decoder.decode([WatchEntry].self, from: data) {
            todayEntries = decoded
        }
        currentStreak  = payload["currentStreak"]  as? Int    ?? currentStreak
        totalPoints    = payload["totalPoints"]    as? Int    ?? totalPoints
        level          = payload["level"]          as? Int    ?? level
        totalXP        = payload["totalXP"]        as? Int    ?? totalXP
        rank           = payload["rank"]           as? String ?? rank
        rankEmoji      = payload["rankEmoji"]      as? String ?? rankEmoji
        disciplineScore = payload["disciplineScore"] as? Int  ?? disciplineScore
        lastSyncDate   = Date()
        saveCache()
    }

    // MARK: - Actions

    func completeHabit(_ habitId: UUID) {
        sendMessage(["completeHabit": habitId.uuidString])
        if let i = todayEntries.firstIndex(where: { $0.habitId == habitId }) {
            todayEntries[i].status = "completed"
            totalPoints += todayEntries[i].pointsEarned
        }
        WKInterfaceDevice.current().play(.success)
        withAnimation(.spring()) { justCompletedHabitId = habitId }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.justCompletedHabitId = nil
        }
    }

    func snoozeHabit(_ habitId: UUID) {
        sendMessage(["snoozeHabit": habitId.uuidString])
        if let i = todayEntries.firstIndex(where: { $0.habitId == habitId }) {
            todayEntries[i].status = "snoozed"
        }
        WKInterfaceDevice.current().play(.retry)
    }

    func skipHabit(_ habitId: UUID) {
        sendMessage(["skipHabit": habitId.uuidString])
        if let i = todayEntries.firstIndex(where: { $0.habitId == habitId }) {
            todayEntries[i].status = "skipped"
        }
        WKInterfaceDevice.current().play(.click)
    }

    func requestSync() {
        sendMessage(["requestSync": true])
    }

    private func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.isReachable else {
            try? WCSession.default.updateApplicationContext(message)
            return
        }
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    // MARK: - Cache

    private func saveCache() {
        let encoder = JSONEncoder()
        if let d = try? encoder.encode(habits)      { UserDefaults.standard.set(d, forKey: "wc_habits") }
        if let d = try? encoder.encode(todayEntries) { UserDefaults.standard.set(d, forKey: "wc_entries") }
        UserDefaults.standard.set(currentStreak, forKey: "wc_streak")
        UserDefaults.standard.set(totalPoints,   forKey: "wc_points")
        UserDefaults.standard.set(level,         forKey: "wc_level")
        UserDefaults.standard.set(totalXP,       forKey: "wc_xp")
        UserDefaults.standard.set(rank,          forKey: "wc_rank")
        UserDefaults.standard.set(rankEmoji,     forKey: "wc_rankEmoji")
        // Update complication data
        UserDefaults.standard.set(todayProgress, forKey: "complication_progress")
        UserDefaults.standard.set(currentStreak, forKey: "complication_streak")
    }

    private func loadCachedData() {
        if let d = UserDefaults.standard.data(forKey: "wc_habits"),
           let h = try? decoder.decode([WatchHabit].self, from: d) { habits = h }
        if let d = UserDefaults.standard.data(forKey: "wc_entries"),
           let e = try? decoder.decode([WatchEntry].self, from: d) { todayEntries = e }
        currentStreak = UserDefaults.standard.integer(forKey: "wc_streak")
        totalPoints   = UserDefaults.standard.integer(forKey: "wc_points")
        level         = UserDefaults.standard.integer(forKey: "wc_level")
        totalXP       = UserDefaults.standard.integer(forKey: "wc_xp")
        rank          = UserDefaults.standard.string(forKey:  "wc_rank")      ?? "Novice"
        rankEmoji     = UserDefaults.standard.string(forKey:  "wc_rankEmoji") ?? "🌱"
    }
}

// MARK: - Watch-side Models (stripped-down, Codable-compatible with iOS models)

struct WatchHabit: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var category: String
    var rewardPoints: Int
    var xpReward: Int
    var scheduledTime: Date?
    var difficulty: String
}

struct WatchEntry: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    let date: Date
    var status: String        // "pending" | "completed" | "snoozed" | "skipped" | "missed"
    var completedAt: Date?
    var pointsEarned: Int
    var snoozeCount: Int

    var isDone: Bool { status == "completed" }
    var isPending: Bool { status == "pending" || status == "snoozed" }
}
