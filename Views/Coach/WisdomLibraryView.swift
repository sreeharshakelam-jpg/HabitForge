import SwiftUI

// MARK: - Wisdom Library View
// Browse all timeless wisdom quotes from the Bhagavad Gita, Stoic
// philosophers, Zen masters, and modern self-improvement classics.
struct WisdomLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSource: WisdomSource? = nil

    var filteredQuotes: [WisdomQuote] {
        if let source = selectedSource {
            return WisdomLibrary.quotes(from: source)
        }
        return WisdomLibrary.all
    }

    var body: some View {
        NavigationView {
            ZStack {
                ForgeColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Source filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            SourceChip(label: "All", color: ForgeColor.accent, isSelected: selectedSource == nil) {
                                selectedSource = nil
                            }
                            ForEach(WisdomSource.allCases, id: \.self) { source in
                                SourceChip(
                                    label: source.rawValue,
                                    color: Color(hex: source.color) ?? .orange,
                                    isSelected: selectedSource == source
                                ) {
                                    selectedSource = (selectedSource == source) ? nil : source
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)

                    // Quote list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredQuotes) { quote in
                                QuoteCard(quote: quote)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Wisdom Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(ForgeColor.accent)
                }
            }
        }
    }
}

// MARK: - Source Chip
private struct SourceChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : ForgeColor.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : ForgeColor.surfaceElevated)
                .overlay(
                    Capsule().stroke(isSelected ? color : ForgeColor.border, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quote Card
private struct QuoteCard: View {
    let quote: WisdomQuote
    @State private var showReflection = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: quote.source.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: quote.source.color) ?? .orange)
                Text(quote.source.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(Color(hex: quote.source.color) ?? .orange)
                Spacer()
                if let ref = quote.reference {
                    Text(ref)
                        .font(.system(size: 10))
                        .foregroundColor(ForgeColor.textTertiary)
                }
            }

            Text("\u{201C}\(quote.text)\u{201D}")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("— \(quote.author)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ForgeColor.textSecondary)
                Spacer()
                if quote.reflection != nil {
                    Button {
                        withAnimation { showReflection.toggle() }
                    } label: {
                        Text(showReflection ? "Hide reflection" : "Reflection")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ForgeColor.accent)
                    }
                }
            }

            if showReflection, let reflection = quote.reflection {
                Text(reflection)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(ForgeColor.textSecondary)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ForgeColor.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ForgeColor.border, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if quote.reflection != nil {
                withAnimation { showReflection.toggle() }
            }
        }
    }
}
