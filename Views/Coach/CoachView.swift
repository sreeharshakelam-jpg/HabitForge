import SwiftUI

// MARK: - AI Discipline Coach Tab
// The headline differentiating feature of FORGE. Uses the user's own Anthropic
// API key (Bring-Your-Own-Key) so there is no backend and no shared cost.
struct CoachView: View {
    @EnvironmentObject var coach: ClaudeCoachService

    @State private var draft: String = ""
    @State private var showAPIKeySheet = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    if !coach.hasAPIKey {
                        apiKeyPrompt
                    } else {
                        if coach.messages.isEmpty {
                            emptyState
                        } else {
                            messageList
                        }
                        quickActions
                        composer
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAPIKeySheet) {
                APIKeySheet()
                    .environmentObject(coach)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FORGE COACH")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(ForgeColor.textTertiary)
                Text("Your AI Discipline Coach")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Menu {
                Button("Reset Conversation", role: .destructive) {
                    coach.clearHistory()
                }
                Button("Manage API Key") {
                    showAPIKeySheet = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(ForgeColor.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(ForgeColor.accent.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(ForgeColor.accent)
            }
            Text("Tap a mission below")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text("Your coach sees your real habits, streak, and discipline score — and gives you specific, tactical guidance.")
                .font(.system(size: 14))
                .foregroundColor(ForgeColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - API Key Prompt
    private var apiKeyPrompt: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 44))
                .foregroundColor(ForgeColor.accent)
            Text("Activate Your Coach")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text("FORGE Coach runs on your own free Anthropic API key. You stay in control of usage and cost — we don't route anything through our servers.")
                .font(.system(size: 14))
                .foregroundColor(ForgeColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                showAPIKeySheet = true
            } label: {
                Text("Add API Key")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(ForgeColor.accent)
                    .clipShape(Capsule())
            }

            Link("Get a free key at console.anthropic.com",
                 destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                .font(.system(size: 13))
                .foregroundColor(ForgeColor.accentBright)
            Spacer()
        }
    }

    // MARK: - Messages
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(coach.messages) { msg in
                        CoachBubble(message: msg).id(msg.id)
                    }
                    if coach.isThinking {
                        HStack {
                            ThinkingDots()
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .id("thinking")
                    }
                    if let error = coach.lastError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: coach.messages.count) { _ in
                if let last = coach.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuickActionChip(icon: "sunrise.fill", label: "Morning Mission") {
                    Task { await coach.runMorningMission() }
                }
                QuickActionChip(icon: "moon.stars.fill", label: "Evening Review") {
                    Task { await coach.runEveningReview() }
                }
                QuickActionChip(icon: "bolt.fill", label: "I'm Stuck") {
                    Task { await coach.send(userMessage: "I'm feeling stuck right now. Pull me out of it with one specific next action I can do in the next 10 minutes.") }
                }
                QuickActionChip(icon: "flame.fill", label: "Protect Streak") {
                    Task { await coach.send(userMessage: "Help me protect my current streak. What's the minimum I must do today to keep it alive?") }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Composer
    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask your coach anything…", text: $draft, axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ForgeColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                let text = draft
                draft = ""
                inputFocused = false
                Task { await coach.send(userMessage: text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(draft.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? ForgeColor.textTertiary
                                    : ForgeColor.accent)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || coach.isThinking)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ForgeColor.background)
    }
}

// MARK: - Bubble
private struct CoachBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    Text("FORGE COACH")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(ForgeColor.accent)
                }
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        message.role == .user
                            ? ForgeColor.accent
                            : ForgeColor.surfaceElevated
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Thinking Animation
private struct ThinkingDots: View {
    @State private var phase = 0
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(ForgeColor.accent)
                    .frame(width: 8, height: 8)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .padding(12)
        .background(ForgeColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

// MARK: - Quick Action Chip
private struct QuickActionChip: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(ForgeColor.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ForgeColor.accent.opacity(0.4), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
    }
}

// MARK: - API Key Entry Sheet
struct APIKeySheet: View {
    @EnvironmentObject var coach: ClaudeCoachService
    @Environment(\.dismiss) var dismiss
    @State private var key: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Your API key is stored only on this device (iOS Keychain). It is sent directly to Anthropic — FORGE never sees or stores it on any server.")
                        .font(.system(size: 13))
                        .foregroundColor(ForgeColor.textSecondary)

                    SecureField("sk-ant-...", text: $key)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(ForgeColor.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Link("How to get a free API key →",
                         destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                        .font(.system(size: 13))
                        .foregroundColor(ForgeColor.accentBright)

                    Spacer()

                    Button {
                        coach.saveAPIKey(key)
                        dismiss()
                    } label: {
                        Text("Save Key")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ForgeColor.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty)

                    if coach.hasAPIKey {
                        Button(role: .destructive) {
                            coach.clearAPIKey()
                            key = ""
                        } label: {
                            Text("Remove Saved Key")
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("FORGE Coach Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(ForgeColor.textSecondary)
                }
            }
        }
    }
}
