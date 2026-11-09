import SwiftUI

@main
struct LearningStreakApp: App {
    @StateObject private var store = LearningStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(.appOrange)
        }
    }
}

/// Pages you can open from the Activity page.
enum Route: Hashable {
    case learningGoal   // Task 3 + Task 4
    case calendar       // Task 5
}

/// Task 1 shows Onboarding first. After "Start Learning" the app lives on the Activity page.
struct RootView: View {
    @EnvironmentObject private var store: LearningStore

    var body: some View {
        Group {
            if store.hasOnboarded {
                NavigationStack {
                    ActivityPage()                                   // Task 2
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .learningGoal: LearningGoalPage()   // Task 3 / Task 4
                            case .calendar: ActivitiesCalendarPage() // Task 5
                            }
                        }
                }
            } else {
                OnboardingPage()                                     // Task 1
            }
        }
        .animation(.easeInOut, value: store.hasOnboarded)
    }
}

#Preview("Full App – start from Onboarding") {
    RootView()
        .environmentObject(LearningStore.sample(onboarded: false))
        .preferredColorScheme(.dark)
        .tint(.appOrange)
}

#Preview("Full App – Activity") {
    RootView()
        .environmentObject(LearningStore.sample(learned: 4))
        .preferredColorScheme(.dark)
        .tint(.appOrange)
}
