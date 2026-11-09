import Foundation
import SwiftUI

// MARK: - Types

enum GoalDuration: String, CaseIterable, Codable, Identifiable {
    case week, month, year

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    /// How many logged days complete the goal.
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
    /// Counters for the current goal.
    var learnedDays = 0
    var freezedDays = 0
    /// Last time a day was logged (or the goal was set).
    var lastActionDate: Date?
    var status: GoalStatus = .active
}

// MARK: - Store (all the app logic lives here)

final class LearningStore: ObservableObject {
    /// Streak resets after more than 32 hours without logging Learned or using a Freeze.
    static let streakWindow: TimeInterval = 32 * 60 * 60

    @Published private(set) var data: AppData {
        didSet { if persists { save() } }
    }
    /// Refreshed every minute and at 12 AM so "today" is always correct.
    @Published private(set) var now = Date()

    private let storageKey = "LearningStreak.AppData"
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
    var learnedDays: Int { data.learnedDays }
    var freezedDays: Int { data.freezedDays }
    var maxFreezes: Int { data.duration.maxFreezes }

    func status(on date: Date) -> DayStatus? { data.history[AppCalendar.key(date)] }
    var todayStatus: DayStatus? { status(on: now) }

    /// Buttons are disabled if a day is logged. Today's key changes at 12 AM,
    /// so they are enabled again at 12 AM even if the user logged at 11 PM.
    var canLogLearned: Bool { data.status == .active && todayStatus == nil }

    /// ...and the Freeze button is also disabled if all Freezes are used.
    var canFreeze: Bool { canLogLearned && data.freezedDays < maxFreezes }

    var allFreezesUsed: Bool { data.freezedDays >= maxFreezes }

    var earliestLoggedDate: Date? {
        data.history.keys.compactMap { AppCalendar.keyFormatter.date(from: $0) }.min()
    }

    // MARK: Task 1 – Start learning

    func startLearning(topic: String, duration: GoalDuration) {
        var d = data
        d.hasOnboarded = true
        d.topic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        d.duration = duration
        startNewStreak(&d)
        data = d
    }

    // MARK: Task 2 – Log a day as learned or freezed

    func logLearned() {
        guard canLogLearned else { return }
        var d = data
        d.history[AppCalendar.key(Date())] = .learned
        d.learnedDays += 1          // streak +1
        d.lastActionDate = Date()
        checkGoalCompleted(&d)
        data = d
    }

    func freezeDay() {
        guard canFreeze else { return }
        var d = data
        d.history[AppCalendar.key(Date())] = .freezed
        d.freezedDays += 1          // freezed days +1, streak is kept
        d.lastActionDate = Date()
        checkGoalCompleted(&d)
        data = d
    }

    /// Task 2 toggle: switch today between Learned and Freezed (or nil = undo).
    /// Switching away from Freezed gives the Freeze back.
    func setToday(_ newStatus: DayStatus?) {
        guard data.status == .active else { return }
        var d = data
        let key = AppCalendar.key(Date())
        let old = d.history[key]
        guard old != newStatus else { return }

        // Can't freeze if all Freezes are used (unless today is already freezed).
        if newStatus == .freezed && d.freezedDays >= d.duration.maxFreezes { return }

        // Take back the old choice
        switch old {
        case .learned: d.learnedDays -= 1
        case .freezed: d.freezedDays -= 1
        case nil: break
        }

        // Apply the new choice
        switch newStatus {
        case .learned: d.learnedDays += 1
        case .freezed: d.freezedDays += 1
        case nil: break
        }
        d.history[key] = newStatus
        if newStatus != nil { d.lastActionDate = Date() }

        checkGoalCompleted(&d)
        now = Date()
        data = d
    }

    // MARK: Task 3 / Task 4 – Set new or same goal, change goal

    /// Updating the learning goal resets the streak.
    func updateGoal(topic: String, duration: GoalDuration) {
        var d = data
        d.topic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        d.duration = duration
        startNewStreak(&d)
        data = d
    }

    // MARK: 32-hour rule

    /// Call on launch, when the app comes back, every minute, and at 12 AM.
    func refresh() {
        now = Date()
        guard data.status == .active,
              let last = data.lastActionDate,
              now.timeIntervalSince(last) > Self.streakWindow else { return }

        var d = data
        if d.learnedDays + d.freezedDays > 0 {
            d.status = .missed               // streak lost → Task 3 "goal not met"
        } else {
            d.lastActionDate = now           // nothing to lose yet
        }
        data = d
    }

    // MARK: Private

    private func startNewStreak(_ d: inout AppData) {
        d.learnedDays = 0
        d.freezedDays = 0
        d.status = .active
        d.lastActionDate = Date()
        now = Date()
    }

    private func checkGoalCompleted(_ d: inout AppData) {
        if d.learnedDays + d.freezedDays >= d.duration.totalDays {
            d.status = .completed
        }
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

        return LearningStore(previewData: AppData(
            hasOnboarded: onboarded,
            topic: onboarded ? "Swift" : "",
            duration: duration,
            history: history,
            learnedDays: learned,
            freezedDays: freezed,
            lastActionDate: Date(),
            status: status))
    }
}
