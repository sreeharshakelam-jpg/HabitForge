import Foundation
import SwiftUI

// MARK: - Coach Message Model
struct CoachMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - FORGE Coach (Offline, Free, Context-Aware)
//
// This is a 100% offline, 100% free coach that reads the user's real habits,
// streak, discipline score, and today's progress, then assembles a response
// from a curated library of templates — including daily wisdom from the
// Bhagavad Gita, Stoic philosophers, and modern self-improvement classics.
//
// There is no API key, no network call, no subscription, and no backend.
// Every user gets the full experience for free.
//
// The class name is kept as ClaudeCoachService for source compatibility with
// the rest of the app, but nothing here calls any external API.
@MainActor
final class ClaudeCoachService: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var isThinking: Bool = false
    @Published var lastError: String?

    // Always true — the coach needs no activation.
    @Published var hasAPIKey: Bool = true

    private let messagesKey = "coach_messages_v2"

    // Injected so the coach can see what the user is actually doing.
    weak var habitStore: HabitStore?

    init() {
        loadMessages()
    }

    // MARK: - API Key (kept as no-ops for source compatibility)
    func saveAPIKey(_ key: String) { /* no-op */ }
    func clearAPIKey() { /* no-op */ }

    // MARK: - Persistence
    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: messagesKey),
              let decoded = try? JSONDecoder().decode([CoachMessage].self, from: data) else { return }
        messages = decoded
    }

    private func saveMessages() {
        let trimmed = Array(messages.suffix(60))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: messagesKey)
        }
    }

    func clearHistory() {
        messages.removeAll()
        saveMessages()
    }

    // MARK: - Public Intents
    func send(userMessage: String) async {
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(CoachMessage(role: .user, content: trimmed))
        saveMessages()
        await respond(to: trimmed)
    }

    func runMorningMission() async {
        messages.append(CoachMessage(role: .user, content: "Give me my morning mission."))
        saveMessages()
        await respond(intent: .morning)
    }

    func runEveningReview() async {
        messages.append(CoachMessage(role: .user, content: "Run my evening review."))
        saveMessages()
        await respond(intent: .evening)
    }

    func runStuckMode() async {
        messages.append(CoachMessage(role: .user, content: "I'm stuck. Help me move."))
        saveMessages()
        await respond(intent: .stuck)
    }

    func runProtectStreak() async {
        messages.append(CoachMessage(role: .user, content: "Help me protect my streak today."))
        saveMessages()
        await respond(intent: .protectStreak)
    }

    // MARK: - Local Response Engine
    private enum Intent {
        case morning, evening, stuck, protectStreak, freeform
    }

    private func respond(to userText: String) async {
        let lower = userText.lowercased()
        let intent: Intent
        if lower.contains("morning") || lower.contains("mission") || lower.contains("today") {
            intent = .morning
        } else if lower.contains("evening") || lower.contains("review") || lower.contains("tonight") || lower.contains("day") {
            intent = .evening
        } else if lower.contains("stuck") || lower.contains("lazy") || lower.contains("tired") || lower.contains("unmotivat") || lower.contains("can't") || lower.contains("don't want") {
            intent = .stuck
        } else if lower.contains("streak") || lower.contains("protect") {
            intent = .protectStreak
        } else {
            intent = .freeform
        }
        await respond(intent: intent)
    }

    private func respond(intent: Intent) async {
        isThinking = true
        // Small delay so the thinking animation is visible and responses feel deliberate.
        try? await Task.sleep(nanoseconds: 600_000_000)
        defer { isThinking = false }

        let reply = buildReply(for: intent)
        messages.append(CoachMessage(role: .assistant, content: reply))
        saveMessages()
    }

    // MARK: - Reply Builder
    private func buildReply(for intent: Intent) -> String {
        let profile = habitStore?.userProfile
        let habits = habitStore?.habits.filter { $0.isActive } ?? []
        let todayEntries = habitStore?.todayEntries ?? []
        let done = todayEntries.filter { $0.status == .completed }.count
        let total = todayEntries.count
        let streak = profile?.currentStreak ?? 0
        let discipline = profile?.disciplineScore ?? 0
        let name = (profile?.name.isEmpty == false) ? (profile?.name ?? "Forger") : "Forger"

        let wisdom = WisdomLibrary.randomForIntent(intent)

        switch intent {
        case .morning:
            let topHabits = habits.prefix(3).map { "• \($0.name)" }.joined(separator: "\n")
            let template = [
                "Morning, \(name). Today's mission is simple: \(total > 0 ? "win \(total) battles" : "set your targets and move").",
                "Stand up. Breathe. Look at today like a chessboard, \(name). \(total) moves to make.",
                "The forge is hot. \(total) habits waiting. Your only job today: show up, not perform."
            ].randomElement() ?? ""
            let habitBlock = topHabits.isEmpty ? "" : "\n\nToday's priorities:\n\(topHabits)"
            let context = "\n\nCurrent streak: \(streak) day\(streak == 1 ? "" : "s") • Discipline: \(discipline)/1000"
            return "\(template)\(habitBlock)\(context)\n\n— — —\n\n\(wisdom)"

        case .evening:
            let rate = total > 0 ? Int(Double(done) / Double(total) * 100) : 0
            let verdict: String
            switch rate {
            case 100: verdict = "A clean day, \(name). Every habit fell in line. Don't let this become the peak — let it become the baseline."
            case 70...99: verdict = "Strong day, \(name). \(done) of \(total) done. The \(total - done) you missed? That's tomorrow's first move."
            case 40...69: verdict = "Mixed day, \(name). \(done) of \(total). You didn't fail — you got data. Tomorrow, attack the one you skipped first."
            case 1...39: verdict = "Rough day, \(name). \(done) of \(total). The test isn't today — it's whether you come back tomorrow."
            default: verdict = "Zero done today, \(name). No lectures. Just this: open the app tomorrow. That's the whole game."
            }
            return "EVENING REVIEW\n\n\(verdict)\n\n— — —\n\n\(wisdom)"

        case .stuck:
            let action = habits.first(where: { e -> Bool in
                todayEntries.first(where: { $0.habitId == e.id })?.status != .completed
            }).map { "Open the app. Tap '\($0.name)'. Do it. Nothing else. 5 minutes." } ?? "Drink a glass of water. Walk 100 steps. That's your next move."
            let lines = [
                "Stuck isn't a feeling, \(name). It's a decision point. Here's the move:",
                "The mind wants a reason to rest. Ignore it. One action, right now:",
                "You don't need motivation. You need momentum. Tiny step:"
            ]
            return "\(lines.randomElement() ?? "")\n\n\(action)\n\n— — —\n\n\(wisdom)"

        case .protectStreak:
            if streak == 0 {
                return "No streak yet, \(name) — so there's nothing to protect. Let's build one. Complete ONE habit today. Just one. That's day 1."
            }
            let easiest = habits.sorted { $0.rewardPoints < $1.rewardPoints }.first
            let action = easiest.map { "Your cheapest win right now: '\($0.name)'. Do that one. Streak saved." } ?? "Pick your smallest habit. Do it. Streak saved."
            return "\(streak)-day streak on the line, \(name). Don't lose what you built.\n\n\(action)\n\n— — —\n\n\(wisdom)"

        case .freeform:
            let responses = [
                "I hear you, \(name). Here's the truth I come back to:",
                "Let me cut through the noise, \(name):",
                "Short answer, \(name):"
            ]
            let insights = [
                "Discipline beats motivation. Motivation is a mood. Discipline is a decision you already made.",
                "You don't rise to the level of your goals. You fall to the level of your habits. Fix the habits.",
                "The gap between who you are and who you want to be is closed by one small action at a time.",
                "Warriors are forged in the boring reps nobody sees.",
                "You can't think your way out of this. You have to act your way out."
            ]
            return "\(responses.randomElement() ?? "")\n\n\(insights.randomElement() ?? "")\n\n— — —\n\n\(wisdom)"
        }
    }
}
