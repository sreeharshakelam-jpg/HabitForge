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

// MARK: - Claude AI Discipline Coach
// Calls the Anthropic Messages API directly using the user's own API key
// (Bring-Your-Own-Key). The key is stored in the iOS Keychain.
@MainActor
final class ClaudeCoachService: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var isThinking: Bool = false
    @Published var lastError: String?
    @Published var hasAPIKey: Bool = false

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5"
    private let keychainKey = "anthropic_api_key"
    private let messagesKey = "coach_messages"

    // Injected so the coach can see what the user is actually doing.
    weak var habitStore: HabitStore?

    init() {
        self.hasAPIKey = (KeychainService.get(keychainKey) != nil)
        loadMessages()
    }

    // MARK: - API Key
    func saveAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainService.set(trimmed, for: keychainKey)
        hasAPIKey = true
    }

    func clearAPIKey() {
        KeychainService.delete(keychainKey)
        hasAPIKey = false
    }

    // MARK: - Persistence
    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: messagesKey),
              let decoded = try? JSONDecoder().decode([CoachMessage].self, from: data) else { return }
        messages = decoded
    }

    private func saveMessages() {
        // Keep only the last 40 messages to bound storage.
        let trimmed = Array(messages.suffix(40))
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
        await callClaude()
    }

    func runMorningMission() async {
        let prompt = "Give me today's morning mission briefing. Be specific, tactical, and under 120 words. Reference my actual habits scheduled for today."
        messages.append(CoachMessage(role: .user, content: prompt))
        saveMessages()
        await callClaude()
    }

    func runEveningReview() async {
        let prompt = "Run my evening after-action review. What did I do well today, what did I fall short on, and what's one specific adjustment for tomorrow? Under 140 words."
        messages.append(CoachMessage(role: .user, content: prompt))
        saveMessages()
        await callClaude()
    }

    // MARK: - Claude API Call
    private func callClaude() async {
        guard let apiKey = KeychainService.get(keychainKey), !apiKey.isEmpty else {
            lastError = "Add your Anthropic API key in Profile → AI Coach to enable the coach."
            hasAPIKey = false
            return
        }

        isThinking = true
        lastError = nil
        defer { isThinking = false }

        let systemPrompt = buildSystemPrompt()
        let apiMessages = messages.map { msg -> [String: String] in
            ["role": msg.role.rawValue, "content": msg.content]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 600,
            "system": systemPrompt,
            "messages": apiMessages
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                lastError = "Network error. Check your connection."
                return
            }
            guard http.statusCode == 200 else {
                let text = String(data: data, encoding: .utf8) ?? ""
                lastError = "Coach unavailable (\(http.statusCode)). \(text.prefix(200))"
                return
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let contentArr = json["content"] as? [[String: Any]],
                  let firstBlock = contentArr.first,
                  let text = firstBlock["text"] as? String else {
                lastError = "Could not parse coach response."
                return
            }

            messages.append(CoachMessage(role: .assistant, content: text))
            saveMessages()
        } catch {
            lastError = "Coach error: \(error.localizedDescription)"
        }
    }

    // MARK: - System Prompt
    private func buildSystemPrompt() -> String {
        var context = ""
        if let store = habitStore {
            let profile = store.userProfile
            let activeHabits = store.habits.filter { $0.isActive }
            let habitLines = activeHabits.prefix(15).map { h -> String in
                let time = h.scheduledTime.map { DateFormatter.shortTime.string(from: $0) } ?? "anytime"
                return "- \(h.name) (\(time), \(h.difficulty.rawValue))"
            }.joined(separator: "\n")

            let todayDone = store.todayEntries.filter { $0.status == .completed }.count
            let todayTotal = store.todayEntries.count

            context = """
            Forger profile:
            - Name: \(profile.name.isEmpty ? "Forger" : profile.name)
            - Level: \(profile.level) (\(profile.rank.displayName))
            - Discipline score: \(profile.disciplineScore)/1000
            - Current streak: \(profile.currentStreak) days
            - Total XP: \(profile.totalXP)
            - Today's progress: \(todayDone)/\(todayTotal) habits completed

            Today's habits:
            \(habitLines.isEmpty ? "(none configured)" : habitLines)
            """
        }

        return """
        You are FORGE Coach — the user's personal discipline coach inside the FORGE app.
        Your voice is direct, warm, and tactical. Think: a seasoned Navy SEAL meets a calm Stoic mentor. No fluff, no emojis unless earned, no therapy-speak.

        Principles:
        - Be specific and actionable. Never vague.
        - Keep responses short by default (under 140 words) unless the user asks for more.
        - Reference the user's actual habits and numbers when you can.
        - Celebrate real wins. Call out avoidance honestly but without shame.
        - Never promise outcomes. Focus on the next small action.
        - You are NOT a medical professional. If the user mentions self-harm, crisis, or serious mental health issues, gently direct them to a professional or crisis line (988 in the US).

        Context you have right now:
        \(context)
        """
    }
}

// Small helper
private extension DateFormatter {
    static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}
