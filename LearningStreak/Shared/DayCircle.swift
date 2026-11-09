import SwiftUI

/// One day number in a circle (used by Task 2 week strip and Task 5 calendar).
/// - Today, not logged yet → solid orange
/// - Learned → orange tint, orange number
/// - Freezed → blue tint, blue number
/// - Other days → plain white number
struct DayCircle: View {
    @EnvironmentObject private var store: LearningStore
    let date: Date
    var size: CGFloat = 44

    var body: some View {
        let status = store.status(on: date)
        let isToday = AppCalendar.calendar.isDate(date, inSameDayAs: store.now)

        Text(AppCalendar.dayNumberFormatter.string(from: date))
            .font(.system(size: size * 0.5, weight: (isToday && status == nil) ? .bold : .medium))
            .foregroundStyle(textColor(status, isToday))
            .frame(width: size, height: size)
            .background(Circle().fill(fillColor(status, isToday)))
    }

    private func textColor(_ status: DayStatus?, _ isToday: Bool) -> Color {
        switch status {
        case .learned: return .appOrange
        case .freezed: return .freezeBlue
        case nil: return .primaryText
        }
    }

    private func fillColor(_ status: DayStatus?, _ isToday: Bool) -> Color {
        switch status {
        case .learned: return .learnedTint
        case .freezed: return .freezedTint
        case nil: return isToday ? .appOrange : .clear
        }
    }
}
