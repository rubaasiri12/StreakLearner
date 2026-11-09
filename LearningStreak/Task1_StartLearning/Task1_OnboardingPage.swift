import SwiftUI

// TASK 1: Start learning!
// Onboarding → Set learning goal and duration → Activity Page

struct OnboardingPage: View {
    @EnvironmentObject private var store: LearningStore
    @State private var topic = ""
    @State private var duration: GoalDuration = .week
    @FocusState private var isTyping: Bool

    private var canStart: Bool {
        !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Flame logo
            HStack {
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.appOrange)
                    .frame(width: 96, height: 96)
                Spacer()
            }
            .padding(.top, 48)
            .padding(.bottom, 48)

            // Hello Learner
            HStack(spacing: 8) {
                Text("Hello")
                Text("Learner").bold()
            }
            .font(.system(size: 34))

            Text("This app will help you learn everyday!")
                .font(.system(size: 17))
                .foregroundStyle(Color.secondaryText)
                .padding(.top, 4)
                .padding(.bottom, 32)

            // Set learning goal and duration
            GoalForm(topic: $topic, duration: $duration, focused: $isTyping)

            Spacer()

            // Start Learning
            VStack(spacing: 10) {
                Button("Start Learning") {
                    isTyping = false
                    store.startLearning(topic: topic, duration: duration)   // → Activity Page
                }
                .buttonStyle(OrangeCapsuleStyle(width: 182))
                .disabled(!canStart)

                Text("You can edit your desire later")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { isTyping = false }
    }
}

#Preview("Task 1 – Onboarding") {
    OnboardingPage()
        .environmentObject(LearningStore.sample(onboarded: false))
        .preferredColorScheme(.dark)
}
