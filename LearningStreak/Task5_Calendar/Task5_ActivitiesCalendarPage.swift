import SwiftUI

// TASK 5: Open Calendar to see all previous learned days
// Activity Page → Calendar icon → Calendar Page
//
// The Activities screen is view only (no interaction with the calendar).
// Orange = learned, blue = freezed, solid orange = today.

struct ActivitiesCalendarPage: View {
    @EnvironmentObject private var store: LearningStore

    /// From the first logged month (at least 3 months back) up to this month.
    private var months: [Date] {
        let cal = AppCalendar.calendar
        let current = AppCalendar.startOfMonth(for: Date())
        let threeBack = cal.date(byAdding: .month, value: -2, to: current) ?? current
        let earliest = AppCalendar.startOfMonth(for: store.earliestLoggedDate ?? threeBack)
        var cursor = min(earliest, threeBack)
        var result: [Date] = []
        while cursor <= current {
            result.append(cursor)
            guard let next = cal.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(months, id: \.self) { month in
                        MonthGrid(monthStart: month)
                            .id(month)
                        Rectangle()
                            .fill(Color.divider)
                            .frame(height: 0.5)
                    }
                }
                .padding(16)
            }
            .onAppear {
                if let current = months.last { proxy.scrollTo(current, anchor: .top) }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MonthGrid: View {
    let monthStart: Date
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppCalendar.monthYearFormatter.string(from: monthStart))
                .font(.system(size: 17, weight: .semibold))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(AppCalendar.shortWeekdays, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondaryText)
                }
                ForEach(Array(AppCalendar.monthGrid(for: monthStart).enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCircle(date: date, size: 40)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .allowsHitTesting(false)   // view only
    }
}

#Preview("Task 5 – Activities calendar") {
    NavigationStack { ActivitiesCalendarPage() }
        .environmentObject(LearningStore.sample(learned: 25, freezed: 4))
        .preferredColorScheme(.dark)
}
