import SwiftUI

// MARK: - Data Models

struct ForgeJournalEntry: Identifiable, Codable {
    let id: UUID
    let lawIndex: Int
    let date: Date
    var text: String

    init(lawIndex: Int, text: String) {
        self.id = UUID()
        self.lawIndex = lawIndex
        self.date = Date()
        self.text = text
    }
}

enum ForgeJournalStore {
    private static let key = "forgeJournal_v1"

    static func load() -> [ForgeJournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ForgeJournalEntry].self, from: data)
        else { return [] }
        return decoded
    }

    static func save(_ entries: [ForgeJournalEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Law Session Data

struct LawSession {
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
    let prompt: String
    let color: Color
    let gradient: LinearGradient
}

let atomicLawSessions: [LawSession] = [
    LawSession(
        number: 1, title: "Make It Obvious", subtitle: "Design your cues", icon: "eye.fill",
        prompt: "What cues or triggers can you place in your environment to make your habits automatic? Where and when will you do it?",
        color: Color(hex: "#3B82F6") ?? .blue,
        gradient: LinearGradient(colors: [Color(hex: "#1D4ED8") ?? .blue, Color(hex: "#60A5FA") ?? .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    ),
    LawSession(
        number: 2, title: "Make It Attractive", subtitle: "Build your craving", icon: "heart.fill",
        prompt: "What do you enjoy that you can pair with your habit? How does this habit connect to the person you want to become?",
        color: Color(hex: "#EC4899") ?? .pink,
        gradient: LinearGradient(colors: [Color(hex: "#BE185D") ?? .pink, Color(hex: "#F472B6") ?? .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
    ),
    LawSession(
        number: 3, title: "Make It Easy", subtitle: "Reduce your friction", icon: "bolt.fill",
        prompt: "What is the 2-minute version of your habit today? What one step can you take to reduce friction and make starting easier?",
        color: Color(hex: "#10B981") ?? .green,
        gradient: LinearGradient(colors: [Color(hex: "#059669") ?? .green, Color(hex: "#34D399") ?? .green], startPoint: .topLeading, endPoint: .bottomTrailing)
    ),
    LawSession(
        number: 4, title: "Make It Satisfying", subtitle: "Reinforce your reward", icon: "star.fill",
        prompt: "How did today's habits feel? What reward are you giving yourself? How are you tracking progress and celebrating your wins?",
        color: Color(hex: "#F59E0B") ?? .orange,
        gradient: LinearGradient(colors: [Color(hex: "#D97706") ?? .orange, Color(hex: "#FCD34D") ?? .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
    ),
]

// MARK: - Main Journal View

struct JourneyJournalView: View {
    @State private var entries: [ForgeJournalEntry] = ForgeJournalStore.load()
    @State private var writingForLaw: Int? = nil
    @State private var draftText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                journalHeader

                ForEach(Array(atomicLawSessions.enumerated()), id: \.offset) { idx, session in
                    LawJournalCard(
                        session: session,
                        entries: entries.filter { $0.lawIndex == idx }.sorted { $0.date > $1.date },
                        onWrite: { draftText = ""; writingForLaw = idx },
                        onDelete: { entry in
                            entries.removeAll { $0.id == entry.id }
                            ForgeJournalStore.save(entries)
                        }
                    )
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, ForgeSpacing.md)
            .padding(.vertical, 16)
        }
        .sheet(item: Binding(
            get: { writingForLaw.map { WritingContext(lawIndex: $0) } },
            set: { writingForLaw = $0?.lawIndex }
        )) { context in
            JournalWritingSheet(
                session: atomicLawSessions[context.lawIndex],
                draftText: $draftText
            ) { text in
                let entry = ForgeJournalEntry(lawIndex: context.lawIndex, text: text)
                entries.insert(entry, at: 0)
                ForgeJournalStore.save(entries)
            }
        }
    }

    private var journalHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ForgeColor.accentGradient)
                    .frame(width: 52, height: 52)
                    .shadow(color: ForgeColor.accent.opacity(0.4), radius: 10)
                Image(systemName: "book.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("ATOMIC JOURNAL")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Text("4 Law Sessions")
                    .font(ForgeTypography.h3)
                    .foregroundColor(ForgeColor.textPrimary)
                Text("Writing cements who you are becoming")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(entries.count)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(ForgeColor.accent)
                Text("total")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(ForgeColor.textTertiary)
            }
        }
        .padding(ForgeSpacing.md)
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.xl).stroke(ForgeColor.accent.opacity(0.2), lineWidth: 1))
    }
}

private struct WritingContext: Identifiable {
    let lawIndex: Int
    var id: Int { lawIndex }
}

// MARK: - Law Journal Card

private struct LawJournalCard: View {
    let session: LawSession
    let entries: [ForgeJournalEntry]
    let onWrite: () -> Void
    let onDelete: (ForgeJournalEntry) -> Void
    @State private var expanded = true

    var body: some View {
        VStack(spacing: 0) {
            lawHeader

            if expanded {
                VStack(spacing: 12) {
                    // Prompt
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 12))
                            .foregroundColor(session.color.opacity(0.7))
                            .padding(.top, 2)
                        Text(session.prompt)
                            .font(ForgeTypography.labelS)
                            .foregroundColor(ForgeColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(ForgeSpacing.md)
                    .background(session.color.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(session.color.opacity(0.18), lineWidth: 1))

                    // Entries list
                    if entries.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 8) {
                            ForEach(entries.prefix(3)) { entry in
                                JournalEntryRow(entry: entry, color: session.color) {
                                    onDelete(entry)
                                }
                            }
                            if entries.count > 3 {
                                Text("+ \(entries.count - 3) more entries")
                                    .font(ForgeTypography.labelXS)
                                    .foregroundColor(ForgeColor.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 2)
                            }
                        }
                    }

                    // Write button
                    Button(action: onWrite) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 13, weight: .semibold))
                            Text(entries.isEmpty ? "Write your first reflection" : "Add new entry")
                                .font(ForgeTypography.labelM)
                        }
                        .foregroundColor(session.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(session.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(session.color.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(ForgeSpacing.md)
            }
        }
        .background(ForgeColor.card)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: ForgeRadius.xl)
                .stroke(expanded ? session.color.opacity(0.25) : ForgeColor.border, lineWidth: 1)
        )
        .shadow(color: expanded ? session.color.opacity(0.1) : .clear, radius: 10)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: expanded)
    }

    private var lawHeader: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { expanded.toggle() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(session.gradient)
                        .frame(width: 52, height: 52)
                        .shadow(color: session.color.opacity(0.45), radius: 8)
                    VStack(spacing: 2) {
                        Text("LAW \(session.number)")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.white.opacity(0.85))
                        Image(systemName: session.icon)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(ForgeTypography.h4)
                        .foregroundColor(ForgeColor.textPrimary)
                    Text(session.subtitle)
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(session.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entries.count)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(entries.isEmpty ? ForgeColor.textTertiary : session.color)
                    Text("entries")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(ForgeColor.textTertiary)
                }

                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ForgeColor.textTertiary)
                    .padding(7)
                    .background(ForgeColor.surfaceElevated)
                    .clipShape(Circle())
            }
            .padding(ForgeSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 28))
                .foregroundColor(session.color.opacity(0.35))
            Text("No entries yet")
                .font(ForgeTypography.labelS)
                .foregroundColor(ForgeColor.textTertiary)
            Text("Tap below to begin your first reflection")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ForgeSpacing.lg)
    }
}

// MARK: - Entry Row

private struct JournalEntryRow: View {
    let entry: ForgeJournalEntry
    let color: Color
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Capsule()
                .fill(color)
                .frame(width: 3)
                .frame(minHeight: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color.opacity(0.85))
                Text(entry.text)
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(ForgeColor.error.opacity(0.6))
                    .padding(7)
                    .background(ForgeColor.error.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(ForgeSpacing.sm)
        .background(ForgeColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
    }
}

// MARK: - Writing Sheet

struct JournalWritingSheet: View {
    let session: LawSession
    @Binding var draftText: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    private var canSave: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ForgeColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(ForgeTypography.labelM)
                        .foregroundColor(ForgeColor.textSecondary)

                    Spacer()

                    Text(session.title)
                        .font(ForgeTypography.h4)
                        .foregroundColor(ForgeColor.textPrimary)

                    Spacer()

                    Button {
                        onSave(draftText.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(canSave ? .white : ForgeColor.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(canSave ? AnyView(session.gradient) : AnyView(ForgeColor.surfaceElevated))
                            .clipShape(Capsule())
                    }
                    .disabled(!canSave)
                }
                .padding(.horizontal, ForgeSpacing.md)
                .padding(.top, 20)
                .padding(.bottom, 14)

                // Law badge row
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(session.gradient)
                            .frame(width: 40, height: 40)
                            .shadow(color: session.color.opacity(0.4), radius: 6)
                        Image(systemName: session.icon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("LAW \(session.number)  ·  \(session.subtitle.uppercased())")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(session.color)
                            .tracking(1)
                        Text(session.title)
                            .font(ForgeTypography.h4)
                            .foregroundColor(ForgeColor.textPrimary)
                    }

                    Spacer()

                    Text(Date(), style: .date)
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                }
                .padding(.horizontal, ForgeSpacing.md)
                .padding(.bottom, 12)

                // Prompt card
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundColor(session.color)
                        .padding(.top, 2)
                    Text(session.prompt)
                        .font(ForgeTypography.labelS)
                        .foregroundColor(ForgeColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(ForgeSpacing.md)
                .background(session.color.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: ForgeRadius.md))
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.md).stroke(session.color.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, ForgeSpacing.md)
                .padding(.bottom, 12)

                Divider().opacity(0.15)

                // Editor
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draftText)
                        .focused($focused)
                        .font(ForgeTypography.bodyM)
                        .foregroundColor(ForgeColor.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, ForgeSpacing.md - 5)
                        .padding(.vertical, ForgeSpacing.sm)

                    if draftText.isEmpty {
                        Text("Write your reflection here...")
                            .font(ForgeTypography.bodyM)
                            .foregroundColor(ForgeColor.textTertiary)
                            .padding(.horizontal, ForgeSpacing.md)
                            .padding(.top, ForgeSpacing.sm + 8)
                            .allowsHitTesting(false)
                    }
                }

                Spacer()
            }
        }
        .onAppear { focused = true }
    }
}
