import Foundation
import WatchConnectivity
import SwiftUI

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isWatchConnected = false
    @Published var isWatchAppInstalled = false
    @Published var lastSyncDate: Date?

    weak var habitStore: HabitStore?
    private var session: WCSession?

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - WCSession Delegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = session.isReachable
        }
    }

    // MARK: - Receive Messages from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            let response = self.handleWatchMessageWithReply(message)
            replyHandler(response)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.handleWatchMessage(applicationContext)
        }
    }

    private func handleWatchMessage(_ message: [String: Any]) {
        guard let store = habitStore else { return }

        if let habitIdString = message["completeHabit"] as? String,
           let habitId = UUID(uuidString: habitIdString) {
            if let entry = store.todayEntries.first(where: { $0.habitId == habitId }) {
                store.completeHabit(entry)
            }
        }

        if let habitIdString = message["snoozeHabit"] as? String,
           let habitId = UUID(uuidString: habitIdString) {
            if let entry = store.todayEntries.first(where: { $0.habitId == habitId }) {
                store.snoozeHabit(entry)
            }
        }

        if let habitIdString = message["skipHabit"] as? String,
           let habitId = UUID(uuidString: habitIdString) {
            if let entry = store.todayEntries.first(where: { $0.habitId == habitId }) {
                store.skipHabit(entry)
            }
        }
    }

    private func handleWatchMessageWithReply(_ message: [String: Any]) -> [String: Any] {
        if message["requestSync"] != nil {
            return buildSyncPayload()
        }
        return [:]
    }

    // MARK: - Send Data to Watch
    func syncHabitsToWatch() {
        guard let session = session, session.isReachable else {
            updateWatchContext()
            return
        }

        let payload = buildSyncPayload()
        session.sendMessage(payload, replyHandler: nil)
        lastSyncDate = Date()
    }

    private func updateWatchContext() {
        guard let session = session else { return }
        let payload = buildSyncPayload()
        try? session.updateApplicationContext(payload)
    }

    private func buildSyncPayload() -> [String: Any] {
        guard let store = habitStore else { return [:] }

        let encoder = JSONEncoder()
        var payload: [String: Any] = [:]

        if let habitsData = try? encoder.encode(store.habits) {
            payload["habits"] = habitsData
        }
        if let entriesData = try? encoder.encode(store.todayEntries) {
            payload["todayEntries"] = entriesData
        }

        payload["currentStreak"] = store.userProfile.currentStreak
        payload["totalPoints"] = store.userProfile.totalPoints
        payload["level"] = store.userProfile.level
        payload["completionRate"] = store.todayCompletionRate
        payload["disciplineScore"] = store.userProfile.disciplineScore
        payload["rank"] = store.userProfile.rank.displayName
        payload["rankEmoji"] = store.userProfile.rank.emoji
        payload["lastSync"] = Date().timeIntervalSince1970

        return payload
    }

    func sendComplicationUpdate() {
        guard let store = habitStore else { return }

        let data: [String: Any] = [
            "currentStreak": store.userProfile.currentStreak,
            "todayProgress": store.todayCompletionRate,
            "pendingCount": store.todayEntries.filter { $0.status == .pending }.count,
            "level": store.userProfile.level
        ]

        try? session?.updateApplicationContext(data)
    }
}
