import SwiftUI

// MARK: - Self-Image (Psycho-Cybernetics)
// "The self-image sets the boundaries of individual accomplishment."
// The avatar is a living visualization of the user's self-image: it gains
// visible muscle as habits are completed, flexes on wins, and changes
// pose/facing daily. These components are composed into the Avatar home tab.

// MARK: - Physique Model

enum PhysiqueStage: Int, CaseIterable {
    case rookie = 0, toned, athlete, warrior, titan, legend

    var name: String {
        switch self {
        case .rookie: return "Rookie"
        case .toned: return "Toned"
        case .athlete: return "Athlete"
        case .warrior: return "Warrior"
        case .titan: return "Titan"
        case .legend: return "Legend"
        }
    }

    var threshold: Int {
        switch self {
        case .rookie: return 0
        case .toned: return 15
        case .athlete: return 40
        case .warrior: return 80
        case .titan: return 150
        case .legend: return 250
        }
    }

    static func stage(for completions: Int) -> PhysiqueStage {
        allCases.last { completions >= $0.threshold } ?? .rookie
    }

    /// Continuous 0...1 muscle factor, smooth between stage thresholds.
    static func muscleFactor(for completions: Int) -> Double {
        let s = stage(for: completions)
        guard s != .legend else { return 1.0 }
        let next = PhysiqueStage(rawValue: s.rawValue + 1)!
        let span = Double(next.threshold - s.threshold)
        let into = Double(completions - s.threshold)
        let base = Double(s.rawValue) / 5.0
        return min(1.0, base + (into / span) * 0.2)
    }
}

enum AvatarGender: String {
    case man, woman
}

// MARK: - Avatar Hero Card (the star: flexes on completion)

struct AvatarHeroCard: View {
    @EnvironmentObject var habitStore: HabitStore
    @AppStorage("avatarGender") private var genderRaw = "man"
    @State private var flexing = false

    private var gender: AvatarGender { AvatarGender(rawValue: genderRaw) ?? .man }
    private var completions: Int { habitStore.userProfile.totalHabitsCompleted }
    private var stage: PhysiqueStage { PhysiqueStage.stage(for: completions) }
    private var muscle: Double { PhysiqueStage.muscleFactor(for: completions) }
    private var completedToday: Int { habitStore.todayEntries.filter { $0.status == .completed }.count }
    private var dayOfYear: Int { Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1 }
    private var facingRight: Bool { dayOfYear % 2 == 0 }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SELF-IMAGE")
                        .font(ForgeTypography.labelXS)
                        .foregroundColor(ForgeColor.textTertiary)
                        .tracking(2)
                    Text("The Person You're Becoming")
                        .font(ForgeTypography.h3)
                        .foregroundColor(ForgeColor.textPrimary)
                }
                Spacer()
                HStack(spacing: 4) {
                    genderButton("♂", .man)
                    genderButton("♀", .woman)
                }
            }

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ForgeColor.accent.opacity(0.25 + muscle * 0.2), .clear],
                            center: .center, startRadius: 10, endRadius: 150
                        )
                    )
                    .frame(width: 280, height: 280)

                AnimeAvatarView(gender: gender, muscle: muscle, flexing: flexing)
                    .frame(width: 220, height: 300)
                    .scaleEffect(x: facingRight ? 1 : -1)
                    .scaleEffect(flexing ? 1.05 : 1.0)
                    .onTapGesture { triggerFlex() }
            }

            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 13, weight: .bold))
                Text(stage.name.uppercased())
                    .font(ForgeTypography.labelM)
                    .tracking(2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Capsule().fill(ForgeColor.accentGradient))
            .shadow(color: ForgeColor.accent.opacity(0.4), radius: 8)

            Text(flexing ? "LET'S GOOO! 💪" : "Tap to flex · Completing habits builds muscle")
                .font(ForgeTypography.labelXS)
                .foregroundColor(flexing ? ForgeColor.accent : ForgeColor.textTertiary)
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.xl)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.xl).stroke(ForgeColor.accent.opacity(0.25), lineWidth: 1))
        )
        .onChange(of: completedToday) { _ in triggerFlex() }
        .onAppear {
            if completedToday > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { triggerFlex() }
            }
        }
    }

    private func triggerFlex() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { flexing = true }
        ForgeHaptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.6)) { flexing = false }
        }
    }

    private func genderButton(_ symbol: String, _ g: AvatarGender) -> some View {
        Button {
            withAnimation(.spring(response: 0.4)) { genderRaw = g.rawValue }
            ForgeHaptics.impact(.light)
        } label: {
            Text(symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(gender == g ? .white : ForgeColor.textSecondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(gender == g ? ForgeColor.accent : ForgeColor.surfaceElevated))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Physique Progress Card

struct PhysiqueProgressCard: View {
    @EnvironmentObject var habitStore: HabitStore

    private var completions: Int { habitStore.userProfile.totalHabitsCompleted }
    private var stage: PhysiqueStage { PhysiqueStage.stage(for: completions) }
    private var progressToNext: Double {
        guard let next = PhysiqueStage(rawValue: stage.rawValue + 1) else { return 1 }
        let span = Double(next.threshold - stage.threshold)
        return min(1, Double(completions - stage.threshold) / span)
    }

    var body: some View {
        let nextStage = PhysiqueStage(rawValue: stage.rawValue + 1)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PHYSIQUE PROGRESS")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                Text("\(completions) reps forged")
                    .font(ForgeTypography.labelS)
                    .foregroundColor(ForgeColor.accent)
            }

            if let next = nextStage {
                Text("\(next.threshold - completions) more completions to \(next.name)")
                    .font(ForgeTypography.h4)
                    .foregroundColor(ForgeColor.textPrimary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(ForgeColor.surfaceElevated)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ForgeColor.accentGradient)
                            .frame(width: geo.size.width * progressToNext)
                            .animation(.spring(response: 0.5), value: progressToNext)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(stage.name).font(ForgeTypography.labelXS).foregroundColor(ForgeColor.accent)
                    Spacer()
                    Text(next.name).font(ForgeTypography.labelXS).foregroundColor(ForgeColor.textTertiary)
                }
            } else {
                Text("Maximum physique reached. You ARE the legend.")
                    .font(ForgeTypography.h4)
                    .foregroundColor(ForgeColor.textPrimary)
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        )
    }
}

// MARK: - Self-Image Statement Card

struct SelfImageStatementCard: View {
    @AppStorage("selfImageStatement") private var selfImageStatement = ""
    @State private var editingStatement = false
    @State private var draftStatement = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundColor(ForgeColor.accent)
                Text("MY SELF-IMAGE")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                Button(editingStatement ? "Save" : "Edit") {
                    if editingStatement {
                        selfImageStatement = draftStatement
                    } else {
                        draftStatement = selfImageStatement
                    }
                    editingStatement.toggle()
                }
                .font(ForgeTypography.labelS)
                .foregroundColor(ForgeColor.accent)
            }

            if editingStatement {
                TextEditor(text: $draftStatement)
                    .font(ForgeTypography.bodyM)
                    .foregroundColor(ForgeColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(ForgeColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text(selfImageStatement.isEmpty
                     ? "\"I am the kind of person who...\" — write who you are becoming. Your nervous system can't tell the difference between a vividly imagined identity and a real one."
                     : "\"\(selfImageStatement)\"")
                    .font(selfImageStatement.isEmpty ? ForgeTypography.bodyM : ForgeTypography.h4)
                    .italic()
                    .foregroundColor(selfImageStatement.isEmpty ? ForgeColor.textTertiary : ForgeColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ForgeSpacing.md)
                    .background(ForgeColor.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        )
    }
}

// MARK: - Daily Psycho-Cybernetics Principle Card

struct DailyPrincipleCard: View {
    var body: some View {
        let principle = PsychoCyberneticsLibrary.principleOfTheDay()
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(ForgeColor.accent)
                Text("PSYCHO-CYBERNETICS · DAILY PRINCIPLE")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(1.5)
            }
            Text(principle.title)
                .font(ForgeTypography.h4)
                .foregroundColor(ForgeColor.textPrimary)
            Text(principle.body)
                .font(ForgeTypography.bodyM)
                .foregroundColor(ForgeColor.textSecondary)
            Text("— Maxwell Maltz, Psycho-Cybernetics")
                .font(ForgeTypography.labelXS)
                .foregroundColor(ForgeColor.textTertiary)
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.accent.opacity(0.2), lineWidth: 1))
        )
    }
}

// MARK: - Psycho-Cybernetics Library

struct PCPrinciple {
    let title: String
    let body: String
}

enum PsychoCyberneticsLibrary {
    static let principles: [PCPrinciple] = [
        PCPrinciple(
            title: "Your Self-Image Sets Your Limits",
            body: "You will always act like the sort of person you conceive yourself to be. Expand the self-image and you expand what's possible. Every habit you complete is evidence for a stronger identity."),
        PCPrinciple(
            title: "The Servo-Mechanism",
            body: "Your brain is a goal-striving machine. Give it a clear target — a vivid picture of who you're becoming — and it will steer you there automatically, correcting course like a guided missile."),
        PCPrinciple(
            title: "Theatre of the Mind",
            body: "Your nervous system cannot tell the difference between a real experience and one vividly imagined. Rehearse tomorrow's habits mentally tonight and your body will follow the script."),
        PCPrinciple(
            title: "Act As If",
            body: "Don't wait to feel like the disciplined person. Act as if you already are, and the feeling follows the action. Identity is built from performances, repeated."),
        PCPrinciple(
            title: "Forgive and Reset",
            body: "A guided missile corrects its errors without shame. When you miss a habit, don't replay the failure — register the correction and fire again. Self-criticism cements the old self-image."),
        PCPrinciple(
            title: "Success Breeds Success",
            body: "Small wins reprogram the self-image faster than big intentions. Each completed habit is a 'success experience' your brain files as proof of the new you."),
        PCPrinciple(
            title: "Relax Into It",
            body: "The servo-mechanism works best when you stop forcing. Set the goal, do the rep, and trust the machinery. Strain signals doubt; calm signals certainty.")
    ]

    static func principleOfTheDay() -> PCPrinciple {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return principles[day % principles.count]
    }
}

// MARK: - Mental Rehearsal (Theatre of the Mind timer)

struct MentalRehearsalCard: View {
    @State private var running = false
    @State private var remaining = 300
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "theatermasks.fill")
                    .foregroundColor(ForgeColor.accent)
                Text("THEATRE OF THE MIND")
                    .font(ForgeTypography.labelXS)
                    .foregroundColor(ForgeColor.textTertiary)
                    .tracking(2)
                Spacer()
                if running {
                    Text(timeString)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(ForgeColor.accent)
                }
            }

            Text(running
                 ? "Close your eyes. See tomorrow's you completing every habit — vividly, in detail, as if it's already happening."
                 : "5-minute mental rehearsal. Visualize yourself performing tomorrow's habits perfectly. Your brain will file it as a real success.")
                .font(ForgeTypography.bodyM)
                .foregroundColor(ForgeColor.textSecondary)

            Button {
                running ? stop() : start()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: running ? "stop.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(running ? "End Session" : "Begin Rehearsal")
                        .font(ForgeTypography.labelM)
                }
                .foregroundColor(running ? ForgeColor.error : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: ForgeRadius.md)
                        .fill(running ? AnyShapeStyle(ForgeColor.error.opacity(0.12)) : AnyShapeStyle(ForgeColor.accentGradient))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(ForgeSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ForgeRadius.lg)
                .fill(ForgeColor.card)
                .overlay(RoundedRectangle(cornerRadius: ForgeRadius.lg).stroke(ForgeColor.border, lineWidth: 1))
        )
        .onDisappear { stop() }
    }

    private var timeString: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func start() {
        remaining = 300
        running = true
        ForgeHaptics.impact(.medium)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining > 0 {
                remaining -= 1
            } else {
                stop()
                ForgeHaptics.success()
            }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        running = false
    }
}

// MARK: - Anime Avatar (pure SwiftUI vector drawing)

struct AnimeAvatarView: View {
    let gender: AvatarGender
    let muscle: Double
    let flexing: Bool

    private var m: CGFloat { CGFloat(muscle) }
    private var shoulderHalf: CGFloat {
        gender == .man ? 36 + 24 * m : 30 + 15 * m
    }
    private var armW: CGFloat { (gender == .man ? 15 : 12) + 11 * m }
    private var bicep: CGFloat { (gender == .man ? 18 : 14) + 16 * m }
    private var waistHalf: CGFloat { gender == .man ? 24 + 6 * m : 20 + 3 * m }
    private var skin: Color { Color(hex: "#FFD9B8") ?? .orange }
    private var skinShade: Color { Color(hex: "#F0BE97") ?? .orange }
    private var hairColor: Color { ForgeColor.accent }

    var body: some View {
        ZStack {
            if gender == .woman { womanBackHair }

            legs
            shorts
            torso
            muscleDetail
            arms
            neckAndHead

            if gender == .man { manHair } else { womanFrontHair }
            face
        }
        .frame(width: 220, height: 300)
    }

    private var neckAndHead: some View {
        ZStack {
            Rectangle()
                .fill(skinShade)
                .frame(width: 15 + 6 * m, height: 18)
                .position(x: 110, y: 100)
            Ellipse()
                .fill(skin)
                .frame(width: 62, height: 66)
                .position(x: 110, y: 66)
            Circle().fill(skin).frame(width: 12, height: 12).position(x: 79, y: 68)
            Circle().fill(skin).frame(width: 12, height: 12).position(x: 141, y: 68)
        }
    }

    private var face: some View {
        ZStack {
            eyeView.position(x: 96, y: 70)
            eyeView.position(x: 124, y: 70)
            Capsule().fill(hairColor.opacity(0.9))
                .frame(width: 15, height: 3)
                .rotationEffect(.degrees(flexing ? 12 : 4))
                .position(x: 96, y: flexing ? 57 : 59)
            Capsule().fill(hairColor.opacity(0.9))
                .frame(width: 15, height: 3)
                .rotationEffect(.degrees(flexing ? -12 : -4))
                .position(x: 124, y: flexing ? 57 : 59)
            if flexing {
                Capsule().fill(Color(hex: "#B4553C") ?? .red)
                    .frame(width: 16, height: 7)
                    .position(x: 110, y: 86)
            } else {
                Capsule().fill(Color(hex: "#C96A50") ?? .red)
                    .frame(width: 10, height: 3)
                    .position(x: 110, y: 86)
            }
            if gender == .woman {
                Ellipse().fill(Color.pink.opacity(0.35)).frame(width: 10, height: 5).position(x: 90, y: 79)
                Ellipse().fill(Color.pink.opacity(0.35)).frame(width: 10, height: 5).position(x: 130, y: 79)
            }
        }
    }

    private var eyeView: some View {
        ZStack {
            Ellipse().fill(.white).frame(width: 14, height: 17)
            Ellipse().fill(hairColor).frame(width: 10, height: 13)
            Ellipse().fill(.black).frame(width: 5, height: 8)
            Circle().fill(.white).frame(width: 3.5, height: 3.5).offset(x: -2, y: -3)
        }
    }

    private var manHair: some View {
        SpikyHairShape()
            .fill(hairColor)
            .frame(width: 76, height: 44)
            .position(x: 110, y: 42)
    }

    private var womanBackHair: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(hairColor.opacity(0.85))
            .frame(width: 84, height: 130)
            .position(x: 110, y: 105)
    }

    private var womanFrontHair: some View {
        ZStack {
            Ellipse()
                .fill(hairColor)
                .frame(width: 68, height: 42)
                .position(x: 110, y: 48)
            Capsule().fill(hairColor).frame(width: 13, height: 62).rotationEffect(.degrees(6)).position(x: 82, y: 92)
            Capsule().fill(hairColor).frame(width: 13, height: 62).rotationEffect(.degrees(-6)).position(x: 138, y: 92)
        }
    }

    private var torso: some View {
        TorsoShape(shoulderHalf: shoulderHalf, waistHalf: waistHalf)
            .fill(skin)
            .frame(width: 220, height: 90)
            .position(x: 110, y: 148)
    }

    private var muscleDetail: some View {
        ZStack {
            Ellipse()
                .stroke(skinShade, lineWidth: 2.5)
                .frame(width: 26 + 10 * m, height: 16 + 6 * m)
                .position(x: 110 - (14 + 5 * m), y: 126)
                .opacity(Double(m) * 0.9 + 0.1)
            Ellipse()
                .stroke(skinShade, lineWidth: 2.5)
                .frame(width: 26 + 10 * m, height: 16 + 6 * m)
                .position(x: 110 + (14 + 5 * m), y: 126)
                .opacity(Double(m) * 0.9 + 0.1)

            if m > 0.4 {
                VStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3).stroke(skinShade, lineWidth: 2)
                                .frame(width: 13, height: 9)
                            RoundedRectangle(cornerRadius: 3).stroke(skinShade, lineWidth: 2)
                                .frame(width: 13, height: 9)
                        }
                    }
                }
                .position(x: 110, y: 162)
                .opacity((Double(m) - 0.4) / 0.6)
            }
        }
    }

    private var arms: some View {
        ZStack {
            armView(left: true)
            armView(left: false)
        }
    }

    private func armView(left: Bool) -> some View {
        let sx: CGFloat = left ? -1 : 1
        let shoulderX = 110 + sx * (shoulderHalf - 4)
        let angle: Double = flexing ? Double(sx) * 125 : Double(sx) * 18
        return ZStack {
            Capsule()
                .fill(skin)
                .frame(width: armW, height: 58)
                .offset(y: 26)
                .rotationEffect(.degrees(angle), anchor: .top)
            Circle()
                .fill(skin)
                .frame(width: bicep, height: bicep)
                .offset(y: 22)
                .rotationEffect(.degrees(angle), anchor: .top)
                .offset(x: -sx * 2)
        }
        .position(x: shoulderX, y: 116)
    }

    private var shorts: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(ForgeColor.accentGradient)
                .frame(width: waistHalf * 2 + 8, height: 30)
                .position(x: 110, y: 200)
            if gender == .woman {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ForgeColor.accentGradient)
                    .frame(width: shoulderHalf * 2 - 14, height: 22)
                    .position(x: 110, y: 122)
            }
        }
    }

    private var legs: some View {
        ZStack {
            Capsule().fill(skin).frame(width: 17 + 7 * m, height: 72).position(x: 96, y: 240)
            Capsule().fill(skin).frame(width: 17 + 7 * m, height: 72).position(x: 124, y: 240)
            Capsule().fill(Color(hex: "#2A2A35") ?? .black).frame(width: 26, height: 12).position(x: 94, y: 277)
            Capsule().fill(Color(hex: "#2A2A35") ?? .black).frame(width: 26, height: 12).position(x: 126, y: 277)
        }
    }
}

// MARK: - Custom Shapes

struct TorsoShape: Shape {
    var shoulderHalf: CGFloat
    var waistHalf: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(shoulderHalf, waistHalf) }
        set { shoulderHalf = newValue.first; waistHalf = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let top = rect.minY + 4
        let bottom = rect.maxY - 4
        p.move(to: CGPoint(x: cx - shoulderHalf, y: top))
        p.addQuadCurve(to: CGPoint(x: cx + shoulderHalf, y: top),
                       control: CGPoint(x: cx, y: top - 6))
        p.addCurve(to: CGPoint(x: cx + waistHalf, y: bottom),
                   control1: CGPoint(x: cx + shoulderHalf, y: top + 34),
                   control2: CGPoint(x: cx + waistHalf + 6, y: bottom - 26))
        p.addLine(to: CGPoint(x: cx - waistHalf, y: bottom))
        p.addCurve(to: CGPoint(x: cx - shoulderHalf, y: top),
                   control1: CGPoint(x: cx - waistHalf - 6, y: bottom - 26),
                   control2: CGPoint(x: cx - shoulderHalf, y: top + 34))
        p.closeSubpath()
        return p
    }
}

struct SpikyHairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let baseY = rect.maxY
        p.move(to: CGPoint(x: rect.minX, y: baseY))
        let spikes = 5
        let step = w / CGFloat(spikes)
        for i in 0..<spikes {
            let x0 = rect.minX + CGFloat(i) * step
            let peakX = x0 + step * 0.5
            let peakY = rect.minY + (i % 2 == 0 ? 0 : h * 0.3)
            p.addLine(to: CGPoint(x: peakX, y: peakY))
            p.addLine(to: CGPoint(x: x0 + step, y: baseY - h * 0.35))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: baseY))
        p.closeSubpath()
        return p
    }
}
