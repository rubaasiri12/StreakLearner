import SwiftUI

// TASK 2: Log a day as learned or freezed — ALL IN ONE FILE
// Activity Page → (Learned Today | Freeze Day) → Activity Page
//
// States from the design:
//   Current day default · Learned today · Freezed today · No Freezes available
//
// Toggle behaviour:
//   • Tap "Log as Learned"   → today = Learned  → the Freeze button stays ON (tap it to switch to Freezed)
//   • Tap "Freeze for a day" → today = Freezed  → the Log circle stays ON  (tap it to switch to Learned)
//   • Tap the chosen one again → undo (today is not logged)
//   • Switching from Freezed to Learned gives the Freeze back.
//   • Freeze is OFF only when all Freezes are used (2 / week, 8 / month, 96 / year).
//   • A new day starts at 12 AM, so both are fresh again even if you logged at 11 PM.
//
// When the goal ends, the bottom part becomes Task 3 (completed / not met).

// MARK: - Page

struct ActivityPage: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.scenePhase) private var scenePhase
    private let minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            header
            WeekStrip()
            StreakCards()

            Spacer(minLength: 0)

            switch store.status {
            case .active:
                LogButtons()                           // Task 2
            case .completed:
                GoalFinishedView(goalMet: true)        // Task 3
            case .missed:
                GoalFinishedView(goalMet: false)       // Task 3
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .animation(.snappy, value: store.todayStatus)
        .animation(.snappy, value: store.status)
        // Keep "today" and the 32-hour rule up to date
        .onAppear { store.refresh() }
        .onReceive(minuteTimer) { _ in store.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            DispatchQueue.main.async { store.refresh() }   // 12 AM → new day
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
    }

    /// "Activity", today's date, Calendar icon (Task 5) and Learning goal icon (Task 4).
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity")
                    .font(.system(size: 34, weight: .bold))
                Text(AppCalendar.fullDateFormatter.string(from: store.now))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()
            HStack(spacing: 8) {
                NavigationLink(value: Route.calendar) { CircleIcon(systemName: "calendar") }
                NavigationLink(value: Route.learningGoal) { CircleIcon(systemName: "pencil.and.outline") }
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.top, 8)
    }
}

// MARK: - Week strip (S M T W T F S)

struct WeekStrip: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        let days = AppCalendar.daysOfWeek(containing: store.now)

        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                VStack(spacing: 8) {
                    Text(AppCalendar.letterWeekdays[AppCalendar.calendar.component(.weekday, from: day) - 1])
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                    DayCircle(date: day, size: 44)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Streak cards ("4 days Learned" / "0 days Freezed")

struct StreakCards: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        HStack(spacing: 14) {
            StatCard(icon: "flame.fill", iconColor: .appOrange,
                     count: store.learnedDays, label: "Learned")
            StatCard(icon: "snowflake", iconColor: .freezeBlue,
                     count: store.freezedDays, label: "Freezed")
        }
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
            // Writing rule: "1 day" / "4 days"
            Text("\(count) \(dayWord(count))")
                .font(.system(size: 17, weight: .semibold))
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.cardText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .glassBackground(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

// MARK: - Log circle + Freeze button (toggle)

struct LogButtons: View {
    @EnvironmentObject private var store: LearningStore

    private var today: DayStatus? { store.todayStatus }

    /// Freeze can be chosen if it's already today's choice, or if Freezes are left.
    private var freezeAvailable: Bool {
        today == .freezed || store.freezedDays < store.maxFreezes
    }

    var body: some View {
        VStack(spacing: 28) {
            LogLearnedCircle(isLearned: today == .learned) {
                withAnimation(.snappy) {
                    // Learned → undo, otherwise (nothing / Freezed) → Learned
                    store.setToday(today == .learned ? nil : .learned)
                }
            }

            VStack(spacing: 10) {
                FreezeButton(isFreezed: today == .freezed, available: freezeAvailable) {
                    withAnimation(.snappy) {
                        // Freezed → undo, otherwise (nothing / Learned) → Freezed
                        store.setToday(today == .freezed ? nil : .freezed)
                    }
                }

                Text("\(store.freezedDays) out of \(store.maxFreezes) Freezes used")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondaryText)
                    .contentTransition(.numericText())
            }
        }
    }
}

/// Orange "Log as Learned" ⇄ grey "Logged as Learned".
struct LogLearnedCircle: View {
    let isLearned: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isLearned ? "Logged as Learned" : "Log as Learned")
                .font(.system(size: isLearned ? 17 : 36, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(isLearned ? Color.disabledText : Color.primaryText)
                .padding(36)
                .frame(width: 274, height: 274)
                .background(Circle().fill(isLearned ? Color.loggedCircle : Color.appOrange))
                .overlay(Circle().stroke(isLearned ? Color.loggedCircleBorder : Color.clear, lineWidth: 1))
                .shadow(color: isLearned ? .clear : Color.orangeGlow, radius: 24)
        }
        .buttonStyle(PressStyle())
    }
}

/// Blue "Freeze for a day" ⇄ grey "Freezed for a day".
/// Grey also means "no Freezes left" (then it can't be tapped).
struct FreezeButton: View {
    let isFreezed: Bool
    let available: Bool
    let action: () -> Void

    private var showsBlue: Bool { available && !isFreezed }

    var body: some View {
        Button(action: action) {
            Text(showsBlue ? "Freeze for a day" : "Freezed for a day")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(showsBlue ? Color.primaryText : Color.disabledText)
                .frame(width: 274, height: 48)
                .background(Capsule().fill(showsBlue ? Color.freezeBlue : Color.clear))
                .glassBackground(Capsule(), tint: showsBlue ? .freezeBlue : nil)
        }
        .buttonStyle(PressStyle())
        .disabled(!available)
    }
}

private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}

// MARK: - Previews (press ▶ Live on the canvas to tap the buttons)

#Preview("Task 2 – Current day default") {
    NavigationStack { ActivityPage() }
        .environmentObject(LearningStore.sample(learned: 4))
        .preferredColorScheme(.dark)
}

#Preview("Task 2 – Learned today") {
    NavigationStack { ActivityPage() }
        .environmentObject(LearningStore.sample(learned: 5, today: .learned))
        .preferredColorScheme(.dark)
}

#Preview("Task 2 – Freezed today") {
    NavigationStack { ActivityPage() }
        .environmentObject(LearningStore.sample(learned: 4, freezed: 1, today: .freezed))
        .preferredColorScheme(.dark)
}

#Preview("Task 2 – No Freezes available") {
    NavigationStack { ActivityPage() }
        .environmentObject(LearningStore.sample(learned: 3, freezed: 2))
        .preferredColorScheme(.dark)
}

#Preview("Task 2 – 1 day wording") {
    NavigationStack { ActivityPage() }
        .environmentObject(LearningStore.sample(learned: 1, freezed: 1))
        .preferredColorScheme(.dark)
}
