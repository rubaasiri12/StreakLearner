import Foundation

/// Fixed Gregorian calendar (week starts Sunday, English names) so the app
/// matches the design whatever the phone's calendar settings are.
enum AppCalendar {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        cal.locale = Locale(identifier: "en_US")
        cal.timeZone = .current
        return cal
    }()

    static let keyFormatter = makeFormatter("yyyy-MM-dd", posix: true)
    static let fullDateFormatter = makeFormatter("EEEE, d MMMM")   // Thursday, 24 October
    static let monthYearFormatter = makeFormatter("MMMM yyyy")     // January 2026
    static let dayNumberFormatter = makeFormatter("d")

    static func key(_ date: Date) -> String { keyFormatter.string(from: date) }

    /// "S", "M", "T", ... (Activity page)
    static var letterWeekdays: [String] { calendar.veryShortWeekdaySymbols }
    /// "SUN", "MON", ... (Calendar page)
    static var shortWeekdays: [String] { calendar.shortWeekdaySymbols.map { $0.uppercased() } }

    static func startOfMonth(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    static func daysOfWeek(containing date: Date) -> [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// Month grid cells; `nil` = empty slot before day 1.
    static func monthGrid(for monthStart: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let days: [Date?] = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: monthStart) }
        return Array(repeating: nil, count: leading) + days
    }

    private static func makeFormatter(_ format: String, posix: Bool = false) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: posix ? "en_US_POSIX" : "en_US")
        f.timeZone = calendar.timeZone
        f.dateFormat = format
        return f
    }
}
