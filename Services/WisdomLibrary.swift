import Foundation

// MARK: - Wisdom Source
enum WisdomSource: String, Codable, CaseIterable {
    case bhagavadGita = "Bhagavad Gita"
    case stoic = "Stoic"
    case modern = "Self-Improvement"
    case zen = "Zen"

    var color: String {
        switch self {
        case .bhagavadGita: return "#F59E0B"
        case .stoic: return "#3B82F6"
        case .modern: return "#10B981"
        case .zen: return "#8B5CF6"
        }
    }

    var icon: String {
        switch self {
        case .bhagavadGita: return "sun.max.fill"
        case .stoic: return "building.columns.fill"
        case .modern: return "book.fill"
        case .zen: return "leaf.fill"
        }
    }
}

// MARK: - Wisdom Quote
struct WisdomQuote: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let author: String
    let source: WisdomSource
    let reference: String?   // e.g. "Chapter 2, Verse 47"
    let reflection: String?  // One-line practical takeaway

    init(id: UUID = UUID(), text: String, author: String, source: WisdomSource, reference: String? = nil, reflection: String? = nil) {
        self.id = id
        self.text = text
        self.author = author
        self.source = source
        self.reference = reference
        self.reflection = reflection
    }
}

// MARK: - Wisdom Library
// All quotes are public domain or widely-attributed paraphrases written
// originally for FORGE Coach. Classical texts (Gita, Meditations, Enchiridion)
// are public domain. Modern principles are paraphrased in FORGE's own voice.
enum WisdomLibrary {

    // MARK: - Bhagavad Gita (public domain translations)
    static let gita: [WisdomQuote] = [
        WisdomQuote(
            text: "You have the right to work, but never to the fruit of work. You should never engage in action for the sake of reward, nor should you long for inaction.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 2, Verse 47",
            reflection: "Show up for the work. Release the outcome. This is the heart of discipline."
        ),
        WisdomQuote(
            text: "Perform your duty equipoised, abandoning all attachment to success or failure. Such equanimity is called yoga.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 2, Verse 48",
            reflection: "Steadiness is the highest skill. Win or lose, keep the same posture."
        ),
        WisdomQuote(
            text: "A person can rise through the efforts of their own mind; or draw themselves down, in the same manner. Because each person is their own friend or enemy.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 6, Verse 5",
            reflection: "You are your own forge. No one else can raise or lower you."
        ),
        WisdomQuote(
            text: "For one who has conquered the mind, the mind is the best of friends; but for one who has failed to do so, the mind remains the greatest enemy.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 6, Verse 6",
            reflection: "The first battle is always inside your own head."
        ),
        WisdomQuote(
            text: "Whatever action is performed by a great man, common men follow in his footsteps. Whatever standards he sets by exemplary acts, all the world pursues.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 3, Verse 21",
            reflection: "Be the standard. Someone is always watching, even if only yourself."
        ),
        WisdomQuote(
            text: "Let your concern be with action alone, and never with the fruits of action. Do not let the results of action be your motive, and do not be attached to inaction.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 2, Verse 47",
            reflection: "The process is the reward. Everything else is a bonus."
        ),
        WisdomQuote(
            text: "It is better to live your own destiny imperfectly than to live an imitation of somebody else's life with perfection.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 3, Verse 35",
            reflection: "Your version of the work, done poorly, beats a copied life done perfectly."
        ),
        WisdomQuote(
            text: "The senses are higher than the body, the mind higher than the senses; above the mind is the intellect, and above the intellect is the self.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 3, Verse 42",
            reflection: "When the body says no, go to the mind. When the mind says no, go to the self."
        ),
        WisdomQuote(
            text: "When meditation is mastered, the mind is unwavering, like the flame of a lamp in a windless place.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 6, Verse 19",
            reflection: "Stillness is strength. Build it like you build muscle."
        ),
        WisdomQuote(
            text: "The soul is neither born, nor does it ever die; nor having once existed, does it ever cease to be. The soul is without birth, eternal, immortal, and ageless.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 2, Verse 20",
            reflection: "The essential you cannot be touched by today's failure. Keep going."
        ),
        WisdomQuote(
            text: "Change is the law of the universe. You can be a millionaire or a pauper in an instant.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reflection: "Nothing stays. Your current state — good or bad — is temporary."
        ),
        WisdomQuote(
            text: "A gift is pure when it is given from the heart to the right person at the right time and at the right place, and when we expect nothing in return.",
            author: "Bhagavad Gita",
            source: .bhagavadGita,
            reference: "Chapter 17, Verse 20",
            reflection: "Give without accounting. That is where real freedom lives."
        )
    ]

    // MARK: - Stoic (public domain)
    static let stoic: [WisdomQuote] = [
        WisdomQuote(
            text: "You have power over your mind — not outside events. Realize this, and you will find strength.",
            author: "Marcus Aurelius",
            source: .stoic,
            reference: "Meditations",
            reflection: "Stop trying to control the day. Control the one who meets the day."
        ),
        WisdomQuote(
            text: "Waste no more time arguing what a good man should be. Be one.",
            author: "Marcus Aurelius",
            source: .stoic,
            reference: "Meditations, Book 10",
            reflection: "Less theory. More action."
        ),
        WisdomQuote(
            text: "The impediment to action advances action. What stands in the way becomes the way.",
            author: "Marcus Aurelius",
            source: .stoic,
            reference: "Meditations",
            reflection: "Your obstacle is your curriculum. Study it."
        ),
        WisdomQuote(
            text: "It is not death that a man should fear, but he should fear never beginning to live.",
            author: "Marcus Aurelius",
            source: .stoic,
            reflection: "The real tragedy is a life not started."
        ),
        WisdomQuote(
            text: "Confine yourself to the present.",
            author: "Marcus Aurelius",
            source: .stoic,
            reference: "Meditations, Book 7",
            reflection: "Yesterday is data. Tomorrow is fiction. Only today is yours."
        ),
        WisdomQuote(
            text: "No man is free who is not master of himself.",
            author: "Epictetus",
            source: .stoic,
            reflection: "Freedom begins with self-command, not external options."
        ),
        WisdomQuote(
            text: "It's not what happens to you, but how you react to it that matters.",
            author: "Epictetus",
            source: .stoic,
            reflection: "Life hands you the material. You choose the response."
        ),
        WisdomQuote(
            text: "First say to yourself what you would be; and then do what you have to do.",
            author: "Epictetus",
            source: .stoic,
            reference: "Discourses",
            reflection: "Identity first. Action second. The order matters."
        ),
        WisdomQuote(
            text: "We suffer more often in imagination than in reality.",
            author: "Seneca",
            source: .stoic,
            reflection: "Most fears are previews of a movie that never releases."
        ),
        WisdomQuote(
            text: "It is not that we have a short time to live, but that we waste a lot of it.",
            author: "Seneca",
            source: .stoic,
            reference: "On the Shortness of Life",
            reflection: "Time isn't lost in big dramatic moments. It leaks in the small ones."
        ),
        WisdomQuote(
            text: "Luck is what happens when preparation meets opportunity.",
            author: "Seneca",
            source: .stoic,
            reflection: "Keep sharpening the blade. You won't always know when the fight comes."
        ),
        WisdomQuote(
            text: "Every new beginning comes from some other beginning's end.",
            author: "Seneca",
            source: .stoic,
            reflection: "To start the new, you must close the old — even the one you loved."
        )
    ]

    // MARK: - Modern Self-Improvement (original paraphrases in FORGE's own voice)
    static let modern: [WisdomQuote] = [
        WisdomQuote(
            text: "You do not rise to the level of your goals. You fall to the level of your systems.",
            author: "On Atomic Habits",
            source: .modern,
            reflection: "Build better systems and goals become inevitable byproducts."
        ),
        WisdomQuote(
            text: "Every action you take is a vote for the type of person you wish to become.",
            author: "On Identity-Based Habits",
            source: .modern,
            reflection: "You don't need one big change. You need one more vote today."
        ),
        WisdomQuote(
            text: "Motivation is what gets you started. Habit is what keeps you going.",
            author: "On Discipline",
            source: .modern,
            reflection: "Don't wait to feel like it. That feeling is downstream of the reps."
        ),
        WisdomQuote(
            text: "The cave you fear to enter holds the treasure you seek.",
            author: "Joseph Campbell",
            source: .modern,
            reflection: "Walk toward the thing that scares you. That's where the growth lives."
        ),
        WisdomQuote(
            text: "Discipline equals freedom.",
            author: "On Extreme Discipline",
            source: .modern,
            reflection: "The disciplined life is the only life that's actually free."
        ),
        WisdomQuote(
            text: "If it's important, do it every day. If it's not important, don't do it at all.",
            author: "On Deep Work",
            source: .modern,
            reflection: "Daily or never. The in-between kills everything."
        ),
        WisdomQuote(
            text: "The cost of being wrong is less than the cost of doing nothing.",
            author: "On Action",
            source: .modern,
            reflection: "Bad decisions are recoverable. Paralysis is not."
        ),
        WisdomQuote(
            text: "Don't be afraid of death. Be afraid of an unlived life.",
            author: "On Mortality",
            source: .modern,
            reflection: "Memento mori. Now go build something."
        ),
        WisdomQuote(
            text: "Be so good they can't ignore you.",
            author: "On Craft",
            source: .modern,
            reflection: "Skill is the loudest voice in any room."
        ),
        WisdomQuote(
            text: "Hard choices, easy life. Easy choices, hard life.",
            author: "On Trade-offs",
            source: .modern,
            reflection: "Pick your hard. Everything is hard."
        ),
        WisdomQuote(
            text: "You're always one decision away from a totally different life.",
            author: "On Change",
            source: .modern,
            reflection: "The next decision is waiting. Make it a good one."
        ),
        WisdomQuote(
            text: "The obstacle is the way. The way forward always goes through, not around.",
            author: "On Resistance",
            source: .modern,
            reflection: "Stop looking for the detour. There isn't one."
        )
    ]

    // MARK: - Zen
    static let zen: [WisdomQuote] = [
        WisdomQuote(
            text: "When walking, walk. When eating, eat.",
            author: "Zen Proverb",
            source: .zen,
            reflection: "Presence is the only place life actually happens."
        ),
        WisdomQuote(
            text: "Before enlightenment: chop wood, carry water. After enlightenment: chop wood, carry water.",
            author: "Zen Proverb",
            source: .zen,
            reflection: "The work doesn't change. The one doing it does."
        ),
        WisdomQuote(
            text: "The obstacle is the path.",
            author: "Zen Proverb",
            source: .zen,
            reflection: "What's in your way is what's teaching you."
        ),
        WisdomQuote(
            text: "Let go, or be dragged.",
            author: "Zen Proverb",
            source: .zen,
            reflection: "Some things have to die so you can move."
        ),
        WisdomQuote(
            text: "The master has failed more times than the beginner has even tried.",
            author: "Zen Proverb",
            source: .zen,
            reflection: "Mastery is just failure, metabolized."
        ),
        WisdomQuote(
            text: "A journey of a thousand miles begins with a single step.",
            author: "Lao Tzu",
            source: .zen,
            reflection: "The step is small. The journey is long. Take the step anyway."
        )
    ]

    // MARK: - All
    static var all: [WisdomQuote] { gita + stoic + modern + zen }

    // MARK: - Lookups
    static func quotes(from source: WisdomSource) -> [WisdomQuote] {
        switch source {
        case .bhagavadGita: return gita
        case .stoic: return stoic
        case .modern: return modern
        case .zen: return zen
        }
    }

    static func quoteOfTheDay(for date: Date = Date()) -> WisdomQuote {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = Calendar.current.component(.year, from: date)
        let index = (day + year) % all.count
        return all[index]
    }

    static func random() -> WisdomQuote {
        all.randomElement() ?? gita[0]
    }

    // Picks a short, framed snippet suitable for the end of a coach reply.
    static func randomForIntent(_ intent: Any) -> String {
        let q = random()
        let source = q.source.rawValue.uppercased()
        return "\(source) — \(q.author)\n\"\(q.text)\""
    }
}
