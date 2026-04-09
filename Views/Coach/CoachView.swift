import SwiftUI

// MARK: - FORGE Coach Tab
// Context-aware offline coach combined with timeless wisdom from the
// Bhagavad Gita, Stoic philosophers, Zen masters, and modern classics.
// 100% free for every user. No API key. No account. No backend.
struct CoachView: View {
    @EnvironmentObject var coach: ClaudeCoachService

    @State private var draft: String = ""
    @State private var showWisdomLibrary = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    if coach.messages.isEmpty {
                        emptyState
                    } else {
                        messageList
                    }
                    quickActions
                    composer
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showWisdomLibrary) {
                WisdomLibraryView()
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
                Text("Discipline + Timeless Wisdom")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Button {
                showWisdomLibrary = true
            } label: {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ForgeColor.accent)
            }
            Menu {
                Button("Reset Conversation", role: .destructive) {
                    coach.clearHistory()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(ForgeColor.accent)
                    .padding(.leading, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(ForgeColor.accent.opacity(0.15))
                        .frame(width: 96, height: 96)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(ForgeColor.accent)
                }
                .padding(.top, 20)

                Text("Your daily coach is ready")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Tap a mission below, or ask anything. The coach sees your real habits, streak, and discipline score.")
                    .font(.system(size: 14))
                    .foregroundColor(ForgeColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Daily Wisdom Card
                DailyWisdomCard(quote: WisdomLibrary.quoteOfTheDay()) {
                    showWisdomLibrary = true
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.bottom, 20)
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
                    Task { await coach.runStuckMode() }
                }
                QuickActionChip(icon: "flame.fill", label: "Protect Streak") {
                    Task { await coach.runProtectStreak() }
                }
                QuickActionChip(icon: "book.fill", label: "Wisdom Library") {
                    showWisdomLibrary = true
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
                    .fixedSize(horizontal: false, vertical: true)
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
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
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

// MARK: - Daily Wisdom Card
struct DailyWisdomCard: View {
    let quote: WisdomQuote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: quote.source.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: quote.source.color) ?? .orange)
                    Text("WISDOM OF THE DAY")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.3)
                        .foregroundColor(ForgeColor.textTertiary)
                    Spacer()
                    Text(quote.source.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: quote.source.color) ?? .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((Color(hex: quote.source.color) ?? .orange).opacity(0.12))
                        .clipShape(Capsule())
                }

                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text("— \(quote.author)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ForgeColor.textSecondary)
                    if let ref = quote.reference {
                        Text("· \(ref)")
                            .font(.system(size: 11))
                            .foregroundColor(ForgeColor.textTertiary)
                    }
                }

                if let reflection = quote.reflection {
                    Text(reflection)
                        .font(.system(size: 12, weight: .regular))
                        .italic()
                        .foregroundColor(ForgeColor.textSecondary)
                        .padding(.top, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ForgeColor.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke((Color(hex: quote.source.color) ?? .orange).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
