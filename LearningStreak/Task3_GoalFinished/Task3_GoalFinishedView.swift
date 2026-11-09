import SwiftUI

// TASK 3: Set new / same goal when the goal gets completed
// Activity Page → Set new goal → New Learning goal → Activity Page
//
// Two designs:
//   Activity – goal completed  → "Well done!  Ready for your next goal?"
//   Activity – goal not met    → "You didn't reach your goal this time.  Want to set another goal?"
// "Set a goal" opens the Learning Goal page, filled with the old goal:
// tap ✓ to keep the same goal, or change it for a new one.

struct GoalFinishedView: View {
    let goalMet: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: goalMet ? "hands.and.sparkles.fill" : "xmark.seal")
                .font(.system(size: 40))
                .foregroundStyle(Color.appOrange)

            VStack(spacing: 4) {
                Text(goalMet ? "Well done!" : "You didn't reach your goal this time.")
                    .font(.system(size: 17, weight: .bold))
                Text(goalMet ? "Ready for your next goal?" : "Want to set another goal?")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.secondaryText)
            }
            .multilineTextAlignment(.center)

            NavigationLink(value: Route.learningGoal) {
                Label("Set a goal", systemImage: "arrow.clockwise.circle")
            }
            .buttonStyle(OrangeCapsuleStyle(height: 44))
            .padding(.top, 18)
        }
        .padding(.horizontal, 24)
    }
}

#Preview("Task 3 – Goal completed") {
    NavigationStack { ActivityPage() }
        .environmentObject(LearningStore.sample(learned: 5, freezed: 2, status: .completed))
        .preferredColorScheme(.dark)
}

#Preview("Task 3 – Goal not met") {
    NavigationStack { ActivityPage() }
        .environmentObject(LearningStore.sample(learned: 2, freezed: 2, status: .missed))
        .preferredColorScheme(.dark)
}
