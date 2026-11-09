import Foundation
import SwiftUI

// MARK: - Types

enum GoalDuration: String, CaseIterable, Codable, Identifiable {
    case week, month, year

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    /// How many logged days (learned + freezed) complete the goal.
    var totalDays: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }

    /// Number of Freezes is limited, depending on the selected duration.
    var maxFreezes: Int {
        switch self {
        case .week: return 2     // 2 Freezes in a week
        case .month: return 8    // 8 Freezes in a month
        case .year: return 96    // 96 Freezes in a year
        }
    }
}

enum DayStatus: String, Codable {
    case learned, freezed
}

enum GoalStatus: String, Codable {
    case active      // streak is running
    case completed   // Task 3: "Well done!"
    case missed      // Task 3: "You didn't reach your goal this time."
}

struct AppData: Codable {
    var hasOnboarded = false
    var topic = ""
    var duration: GoalDuration = .week
    /// Every logged day, keyed "yyyy-MM-dd". Feeds the week strip and the calendar.
    var history: [String: DayStatus] = [:]
    /// The day the current goal started. Only days from here on are counted.
    var goalStart: Date?
    /// Last time a day was logged (or the goal was set). Used for the 32-hour rule.
    var lastActionDate: Date?
    var status: GoalStatus = .active
}

// MARK: - Store (all the app logic lives here)

final class LearningStore: ObservableObject {
    /// Streak is lost after more than 32 hours without logging Learned or using a Freeze.
    static let streakWindow: TimeInterval = 32 * 60 * 60

    @Published private(set) var data: AppData {
        didSet { if persists { save() } }
    }
    /// Refreshed every minute and at 12 AM so "today" is always correct.
    @Published private(set) var now = Date()

    private let storageKey = "LearningStreak.AppData.v2"
    private let persists: Bool

    init() {
        persists = true
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
        refresh()
    }

    /// Used by previews: nothing is saved.
    init(previewData: AppData) {
        persists = false
        data = previewData
    }

    // MARK: Read

    var hasOnboarded: Bool { data.hasOnboarded }
    var topic: String { data.topic }
    var duration: GoalDuration { data.duration }
    var status: GoalStatus { data.status }
    var maxFreezes: Int { data.duration.maxFreezes }

    func status(on date: Date) -> DayStatus? { data.history[AppCalendar.key(date)] }
    var todayStatus: DayStatus? { status(on: now) }

    /// Counted straight from the calendar, so they can never go below 0
    /// and always match the coloured days: 0, 1, 2, 3 ...
    var learnedDays: Int { count(.learned) }
    var freezedDays: Int { count(.freezed) }

    var earliestLoggedDate: Date? {
        data.history.keys.compactMap { AppCalendar.keyFormatter.date(from: $0) }.min()
    }

    private func count(_ kind: DayStatus) -> Int {
        let startKey = data.goalStart.map { AppCalendar.key($0) } ?? ""
        return data.history.filter { $0.key >= startKey && $0.value == kind }.count
    }

    // MARK: Task 1 – Start learning

    func startLearning(topic: String, duration: GoalDuration) {
        var d = data
        d.hasOnboarded = true
        d.topic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        d.duration = duration
        startNewGoal(&d)
        data = d
    }

    // MARK: Task 2 – Log a day as learned or freezed (toggle)

    /// Sets today to Learned, Freezed, or nil (undo).
    /// Switching between them moves the day from one counter to the other.
    func setToday(_ newStatus: DayStatus?) {
        guard data.status == .active else { return }
        var d = data
        let key = AppCalendar.key(Date())
        guard d.history[key] != newStatus else { return }

        // Can't freeze if all Freezes are used.
        if newStatus == .freezed && freezedDays >= maxFreezes { return }

        d.history[key] = newStatus
        if newStatus != nil { d.lastActionDate = Date() }
        now = Date()
        data = d

        // Reached the goal (e.g. 7 days in a week, learned or freezed) → "Well done!"
        if learnedDays + freezedDays >= data.duration.totalDays {
            data.status = .completed
        }
    }

    // MARK: Task 3 / Task 4 – Set new or same goal, change goal

    /// Updating the learning goal starts the streak over from 0.
    func updateGoal(topic: String, duration: GoalDuration) {
        var d = data
        d.topic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        d.duration = duration
        startNewGoal(&d)
        data = d
    }

    // MARK: 32-hour rule

    /// Call on launch, when the app comes back, every minute, and at 12 AM.
    /// If more than 32 hours pass without logging → "You didn't reach your goal this time."
    func refresh() {
        now = Date()
        guard data.status == .active,
              let last = data.lastActionDate,
              now.timeIntervalSince(last) > Self.streakWindow else { return }
        data.status = .missed
    }

    // MARK: Private

    /// New goal: counters back to 0, today is fresh, the 32-hour clock starts now.
    /// Old days stay in the calendar (Task 5) but don't count anymore.
    private func startNewGoal(_ d: inout AppData) {
        let today = Date()
        d.history[AppCalendar.key(today)] = nil
        d.goalStart = AppCalendar.calendar.startOfDay(for: today)
        d.status = .active
        d.lastActionDate = today
        now = today
    }

    private func save() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: storageKey)
        }
    }
}

// MARK: - Writing rule

/// If the Streak / Freeze number is 1, the word is "day", not "days".
func dayWord(_ count: Int) -> String { count == 1 ? "day" : "days" }

// MARK: - Preview helper

extension LearningStore {
    /// Builds a store for previews. Past days are filled in going backwards from yesterday.
    static func sample(learned: Int = 0,
                       freezed: Int = 0,
                       today: DayStatus? = nil,
                       duration: GoalDuration = .week,
                       status: GoalStatus = .active,
                       onboarded: Bool = true) -> LearningStore {
        let cal = AppCalendar.calendar
        var history: [String: DayStatus] = [:]
        if let today { history[AppCalendar.key(Date())] = today }

        let pastFreezed = max(freezed - (today == .freezed ? 1 : 0), 0)
        let pastLearned = max(learned - (today == .learned ? 1 : 0), 0)
        var offset = 1
        for _ in 0..<pastFreezed {
            if let d = cal.date(byAdding: .day, value: -offset, to: Date()) { history[AppCalendar.key(d)] = .freezed }
            offset += 1
        }
        for _ in 0..<pastLearned {
            if let d = cal.date(byAdding: .day, value: -offset, to: Date()) { history[AppCalendar.key(d)] = .learned }
            offset += 1
        }
        // The goal started on the oldest sample day, so the counters match.
        let start = cal.date(byAdding: .day, value: -(offset - 1), to: cal.startOfDay(for: Date()))

        return LearningStore(previewData: AppData(
            hasOnboarded: onboarded,
            topic: onboarded ? "Swift" : "",
            duration: duration,
            history: history,
            goalStart: start,
            lastActionDate: Date(),
            status: status))
    }
}
