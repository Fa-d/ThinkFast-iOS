//
//  ContentSelector.swift
//  Intently
//
//  Created on 2025-01-07.
//  Selects appropriate intervention content based on context using weighted randomization
//

import Foundation

/// Selects appropriate intervention content based on context using weighted randomization.
///
/// This is the CORE algorithm that determines what users see on intervention screens.
/// Effectiveness depends on:
/// 1. Variety (prevent habituation)
/// 2. Context awareness (right message at right time)
/// 3. Progressive complexity (gentle → firm)
final class ContentSelector: ObservableObject {

    // MARK: - Content Store
    private let contentStore = JitaiInterventionContentStore()

    // MARK: - State
    private var recentContent: [String] = []
    private let maxRecentContentSize = 10

    // MARK: - Initialization
    init() {}

    // MARK: - Public Methods

    /// Generate content by type name (bypasses randomization)
    /// - Parameters:
    ///   - contentTypeName: The ContentType enum name (e.g., "REFLECTION", "BREATHING")
    ///   - context: Current intervention context
    /// - Returns: Generated intervention content of the specified type
    func generateContentByType(
        contentTypeName: String,
        context: InterventionContext
    ) -> InterventionContentModel {
        let contentType = ContentType(rawValue: contentTypeName) ?? .reflection
        let content = generateContent(contentType: contentType, context: context)
        trackShownContent(content: content)
        return content
    }

    // MARK: - Private Methods

    /// Generates actual content based on selected type and context
    private func generateContent(
        contentType: ContentType,
        context: InterventionContext
    ) -> InterventionContentModel {
        switch contentType {
        case .reflection:
            return generateReflectionQuestion(context: context)
        case .timeAlternative:
            return generateTimeAlternative(context: context)
        case .breathing:
            return generateBreathingExercise(context: context)
        case .stats:
            return generateUsageStats(context: context)
        case .emotionalAppeal:
            return generateEmotionalAppeal(context: context)
        case .quote:
            return generateQuote()
        case .gamification:
            return generateGamification(context: context)
        case .activitySuggestion:
            return generateActivitySuggestion(context: context)
        }
    }

    /// Generates a reflection question appropriate to context
    private func generateReflectionQuestion(context: InterventionContext) -> InterventionContentModel {
        let (category, pool) = reflectionCategoryAndPool(for: context)
        let question = pool.randomElement() ?? "Take a moment to reflect"

        return InterventionContentModel(
            type: .reflection,
            title: "Quick Reflection",
            content: question,
            subtext: "Take a moment to honestly answer",
            actionLabel: "I'll Think About It",
            dismissLabel: "Continue Anyway",
            metadata: ["category": category.rawValue]
        )
    }

    private func reflectionCategoryAndPool(for context: InterventionContext) -> (ReflectionCategory, [String]) {
        if context.isLateNight {
            return (.lateNight, contentStore.lateNightQuestions)
        }
        if context.quickReopenAttempt {
            return (.quickReopen, contentStore.quickReopenQuestions)
        }
        if context.isFirstSessionOfDay {
            return (.triggerAwareness, contentStore.triggerAwarenessQuestions)
        }
        if context.sessionCount > 5 {
            return (.patternRecognition, contentStore.patternRecognitionQuestions)
        }
        if context.currentSessionMinutes > 10 {
            return (.timeAwareness, contentStore.timeAwarenessQuestions)
        }
        if Bool.random() {
            return (.priorityCheck, contentStore.priorityCheckQuestions)
        }
        return (.emotionalAwareness, contentStore.emotionalAwarenessQuestions)
    }

    /// Generates a time alternative with loss framing
    private func generateTimeAlternative(context: InterventionContext) -> InterventionContentModel {
        let sessionMinutes = max(1, context.currentSessionMinutes)
        let alternatives = alternativesForSessionMinutes(sessionMinutes)

        // Select 3-4 random alternatives
        let count = min(alternatives.count, max(3, alternatives.count))
        let selected = alternatives.shuffled().prefix(count)

        let alternativesText = selected.map { "\($0.emoji) \($0.activity)" }.joined(separator: "\n")

        return InterventionContentModel(
            type: .timeAlternative,
            title: "💡 This could have been:",
            content: alternativesText,
            subtext: "What will you remember tomorrow: this scroll, or one of these?",
            actionLabel: "Good Point",
            dismissLabel: "Not Now",
            metadata: ["sessionMinutes": sessionMinutes]
        )
    }

    private func alternativesForSessionMinutes(_ minutes: Int) -> [(activity: String, emoji: String)] {
        switch minutes {
        case 0...2:
            return [
                ("Drink water and feel refreshed", "💧"),
                ("Do 20 push-ups", "💪"),
                ("Text someone you care about", "💬"),
                ("Listen to your favorite song", "🎵")
            ]
        case 3...5:
            return [
                ("A full meditation session", "🧘"),
                ("Read 2-3 pages of a book", "📖"),
                ("Walk around the block", "🚶"),
                ("Sketch something creative", "🎨")
            ]
        case 6...10:
            return [
                ("A 1-2km run", "🏃"),
                ("Read 5-10 pages", "📚"),
                ("A meaningful phone call", "☎️"),
                ("Tidy up your space", "🧹")
            ]
        default:
            return [
                ("A 3km run", "🏃"),
                ("A full chapter of a book", "📖"),
                ("Write in your journal", "✍️"),
                ("Cook a healthy meal", "🍳")
            ]
        }
    }

    /// Generates a breathing exercise
    private func generateBreathingExercise(context: InterventionContext) -> InterventionContentModel {
        let instruction = contentStore.breathingInstructions.randomElement() ?? "Let's take a moment to breathe together"
        let variant: BreathingVariant = context.isLateNight ? .calmBreathing : .fourSevenEight

        let duration: Int
        let description: String
        switch variant {
        case .fourSevenEight:
            duration = 19
            description = "4-7-8 breathing: Inhale 4s, hold 7s, exhale 8s"
        case .boxBreathing:
            duration = 16
            description = "Box breathing: 4s in, 4s hold, 4s out, 4s hold"
        case .calmBreathing:
            duration = 20
            description = "Calm breathing: 5s in, 5s out"
        }

        return InterventionContentModel(
            type: .breathing,
            title: "Pause & Breathe",
            content: description,
            subtext: instruction,
            actionLabel: "Start Breathing",
            dismissLabel: "Skip",
            metadata: ["duration": duration, "variant": variant.rawValue]
        )
    }

    /// Generates usage statistics with motivational message
    private func generateUsageStats(context: InterventionContext) -> InterventionContentModel {
        let message = statsMessage(
            todayMinutes: Int(context.totalUsageToday),
            yesterdayMinutes: Int(context.totalUsageYesterday),
            goalMinutes: context.goalMinutes
        )

        return InterventionContentModel(
            type: .stats,
            title: "Your Usage",
            content: message,
            subtext: "Is it worth it?",
            actionLabel: "I See",
            dismissLabel: "Continue",
            metadata: [
                "today": context.totalUsageToday,
                "yesterday": context.totalUsageYesterday,
                "goal": context.goalMinutes ?? 0
            ]
        )
    }

    private func statsMessage(todayMinutes: Int, yesterdayMinutes: Int, goalMinutes: Int?) -> String {
        let comparison: String
        if yesterdayMinutes == 0 {
            comparison = "Your first session today"
        } else if todayMinutes < yesterdayMinutes {
            let diff = yesterdayMinutes - todayMinutes
            comparison = "You're down \(diff) min from yesterday! 📉"
        } else if todayMinutes > yesterdayMinutes {
            let diff = todayMinutes - yesterdayMinutes
            comparison = "You're up \(diff) min from yesterday"
        } else {
            comparison = "Same usage as yesterday"
        }

        let goalMessage: String
        if let goal = goalMinutes {
            if todayMinutes <= goal {
                goalMessage = "\n\nStill under your \(goal) min goal! 🎯"
            } else {
                let over = todayMinutes - goal
                goalMessage = "\n\nYou're \(over) min over your goal"
            }
        } else {
            goalMessage = ""
        }

        return comparison + goalMessage
    }

    /// Generates an emotional appeal based on context
    private func generateEmotionalAppeal(context: InterventionContext) -> InterventionContentModel {
        let (message, subtext) = emotionalAppealForContext(context)

        return InterventionContentModel(
            type: .emotionalAppeal,
            title: "Remember Your Goals",
            content: message,
            subtext: subtext,
            actionLabel: "You're Right",
            dismissLabel: "Continue",
            metadata: [:]
        )
    }

    private func emotionalAppealForContext(_ context: InterventionContext) -> (String, String) {
        if context.isLateNight {
            return ("It's late. Tomorrow-you will regret this.", "Sleep is more valuable than scrolling")
        }
        if context.isWeekendMorning {
            return ("Is this how you want to spend your Saturday morning?", "You only get so many weekends")
        }
        if context.quickReopenAttempt {
            return ("This is becoming compulsive.", "You're in control. You can stop.")
        }
        if context.isExtendedSession {
            return ("You've been here for 15 minutes.", "What are you really looking for?")
        }
        if context.isHighFrequencyDay {
            return ("This is your 12th session today.", "Notice the pattern?")
        }
        return ("Your time is valuable - spend it wisely", "Think of all the things you could achieve")
    }

    /// Generates an inspirational quote
    private func generateQuote() -> InterventionContentModel {
        let quotes = [
            ("You will never find time for anything. If you want time, you must make it.", "Charles Buxton"),
            ("The cost of a thing is the amount of life which must be exchanged for it.", "Henry David Thoreau"),
            ("Time is what we want most, but what we use worst.", "William Penn"),
            ("The bad news is time flies. The good news is you're the pilot.", "Michael Altshuler")
        ]

        guard let (quote, author) = quotes.randomElement() else {
            return InterventionContentModel(
                type: .quote,
                title: "Words of Wisdom",
                content: "Time is precious",
                subtext: "- Unknown",
                actionLabel: "Inspiring",
                dismissLabel: "Continue",
                metadata: ["author": "Unknown"]
            )
        }

        return InterventionContentModel(
            type: .quote,
            title: "Words of Wisdom",
            content: quote,
            subtext: "- \(author)",
            actionLabel: "Inspiring",
            dismissLabel: "Continue",
            metadata: ["author": author]
        )
    }

    /// Generates a gamification challenge
    private func generateGamification(context: InterventionContext) -> InterventionContentModel {
        if context.currentSessionMinutes < 10 && context.bestSessionMinutes > 10 {
            return InterventionContentModel(
                type: .gamification,
                title: "🏆 Beat Your Record!",
                content: "Stop now at \(context.currentSessionMinutes) min",
                subtext: "New personal best possible!",
                actionLabel: "Challenge Accepted",
                dismissLabel: "Continue",
                metadata: ["target": context.bestSessionMinutes]
            )
        }

        if context.streakDays >= 7 {
            return InterventionContentModel(
                type: .gamification,
                title: "🔥 On a Streak!",
                content: "You're on a \(context.streakDays)-day streak!",
                subtext: "Keep it going!",
                actionLabel: "Let's Go!",
                dismissLabel: "Continue",
                metadata: ["streak": context.streakDays]
            )
        }

        // Fallback to reflection
        return generateReflectionQuestion(context: context)
    }

    /// Generates an activity suggestion based on time of day
    private func generateActivitySuggestion(context: InterventionContext) -> InterventionContentModel {
        let timeContext = activityTimeContext(context.timeOfDay)
        let suggestions = suggestionsForTimeContext(timeContext)
        guard let suggestion = suggestions.randomElement() else {
            return InterventionContentModel(
                type: .activitySuggestion,
                title: "💡",
                content: "Try something new",
                subtext: "A better use of your time",
                actionLabel: "Let's Do It",
                dismissLabel: "Maybe Later",
                metadata: ["timeContext": ActivityTimeContext.morning.rawValue]
            )
        }

        return InterventionContentModel(
            type: .activitySuggestion,
            title: suggestion.1,
            content: suggestion.0,
            subtext: "A better use of your time",
            actionLabel: "Let's Do It",
            dismissLabel: "Maybe Later",
            metadata: ["timeContext": timeContext.rawValue]
        )
    }

    private func activityTimeContext(_ hour: Int) -> ActivityTimeContext {
        switch hour {
        case 6...9: return .morning
        case 10...14: return .midday
        case 15...19: return .evening
        default: return .lateNight
        }
    }

    private func suggestionsForTimeContext(_ context: ActivityTimeContext) -> [(String, String)] {
        switch context {
        case .morning:
            return [
                ("Go outside for 5 minutes of sunlight", "☀️"),
                ("Make your coffee mindfully", "☕"),
                ("Start your day with 5-minute meditation", "🧘"),
                ("Take a quick morning walk", "🏃")
            ]
        case .midday:
            return [
                ("Eat lunch without your phone", "🥗"),
                ("Take a 10-minute walk outside", "🚶"),
                ("Drink water + stretch for 5 minutes", "💧"),
                ("Call a friend or family member", "📞")
            ]
        case .evening:
            return [
                ("Get some exercise before dinner", "🏃"),
                ("Cook something healthy", "🍳"),
                ("Read for 15 minutes", "📚"),
                ("Work on a hobby or side project", "🎨")
            ]
        case .lateNight:
            return [
                ("Wind down for better sleep", "😴"),
                ("Read a physical book", "📖"),
                ("Try evening meditation", "🧘"),
                ("Take a relaxing bath or shower", "🛁")
            ]
        }
    }

    /// Tracks shown content to prevent immediate repeats
    private func trackShownContent(content: InterventionContentModel) {
        let contentKey = "\(content.type.rawValue):\(content.content.prefix(20))"
        recentContent.append(contentKey)

        if recentContent.count > maxRecentContentSize {
            recentContent.removeFirst()
        }
    }

    /// Checks if content was recently shown (for testing/debugging)
    func wasRecentlyShown(contentKey: String) -> Bool {
        return recentContent.contains(contentKey)
    }

    /// Clears recent content history (for testing)
    func clearHistory() {
        recentContent.removeAll()
    }
}

// MARK: - Supporting Types

enum ReflectionCategory: String {
    case triggerAwareness = "TRIGGER_AWARENESS"
    case priorityCheck = "PRIORITY_CHECK"
    case emotionalAwareness = "EMOTIONAL_AWARENESS"
    case patternRecognition = "PATTERN_RECOGNITION"
    case timeAwareness = "TIME_AWARENESS"
    case lateNight = "LATE_NIGHT"
    case quickReopen = "QUICK_REOPEN"
}

enum BreathingVariant: String {
    case fourSevenEight = "FOUR_SEVEN_EIGHT"
    case boxBreathing = "BOX_BREATHING"
    case calmBreathing = "CALM_BREATHING"
}

enum ActivityTimeContext: String {
    case morning = "MORNING"
    case midday = "MIDDAY"
    case evening = "EVENING"
    case lateNight = "LATE_NIGHT"
}

// MARK: - Intervention Content Model

struct InterventionContentModel: Identifiable {
    let id = UUID()
    let type: ContentType
    let title: String
    let content: String
    let subtext: String
    let actionLabel: String
    let dismissLabel: String
    let metadata: [String: Any]
}

// MARK: - Intervention Content Store

class JitaiInterventionContentStore {
    // Reflection Questions
    let triggerAwarenessQuestions = [
        "What was happening before you felt the urge to open this?",
        "What are you trying to avoid or escape from?",
        "What pattern keeps bringing you back here?",
        "What triggered this impulse to scroll?",
        "What specific thought made you reach for this app?",
        "What would happen if you waited 5 minutes before opening this?",
        "Is this a habit or a conscious choice?",
        "When did you decide to open this app?",
        "What were you doing just before you felt this urge?"
    ]

    let priorityCheckQuestions = [
        "Is this the most important thing right now?",
        "What could you do instead that future-you would thank you for?",
        "Are you here for something specific, or just browsing?",
        "Would you do this if someone was watching?",
        "What's the best use of the next 10 minutes?",
        "If you had only 30 minutes of free time today, would you spend it here?",
        "What's waiting for you that matters more than this?",
        "What would your best self choose to do right now?",
        "Is scrolling your top priority at this moment?",
        "What did you intend to do before picking up your phone?"
    ]

    let emotionalAwarenessQuestions = [
        "How are you feeling right now? Bored? Stressed? Anxious?",
        "Will scrolling actually make you feel better?",
        "When was the last time scrolling made you genuinely happy?",
        "What emotion are you trying to satisfy?",
        "How will you feel after 20 minutes of scrolling?",
        "Are you running toward something or away from something?",
        "What feeling are you trying to escape right now?",
        "Will scrolling fix the real issue?",
        "What would help you feel better than scrolling?",
        "Are you trying to fill a void or avoid discomfort?"
    ]

    let patternRecognitionQuestions = [
        "You've done this before. What happened last time?",
        "Is this becoming a habit you want to keep?",
        "What would break this cycle?",
        "How many times this week have you opened this?"
    ]

    let timeAwarenessQuestions = [
        "How many times have you chosen scrolling over this recently?",
        "What will you remember about today when you look back?",
        "Is this moment worth trading for endless scrolling?",
        "How do you want to feel at the end of today?",
        "What's the opportunity cost of the next 10 minutes here?"
    ]

    let lateNightQuestions = [
        "Are you scrolling to avoid sleeping?",
        "Your future self needs rest more than you need scrolling.",
        "Will this be worth being tired tomorrow?",
        "What time did you want to sleep tonight?"
    ]

    let quickReopenQuestions = [
        "You just closed this. What changed?",
        "You've opened this %d times today. What are you looking for?",
        "Is this becoming compulsive?",
        "Take a breath. Do you really need to check again?"
    ]

    let breathingInstructions = [
        "Let's take a moment to breathe together",
        "Your mind needs a break. Let's breathe.",
        "Before you continue, let's ground ourselves with breathing"
    ]
}
