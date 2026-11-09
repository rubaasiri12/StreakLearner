import SwiftUI

// TASK 4: Change Learning goal
// Activity Page → Learning goal icon → Change learning goal / duration → Activity Page
//
// Designs: Update goal · Update goal (keyboard) · Update goal (Alert)
// Updating the goal resets the streak, so we warn first.

struct LearningGoalPage: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss

    @State private var topic = ""
    @State private var duration: GoalDuration = .week
    @State private var loaded = false
    @State private var showAlert: Bool
    @FocusState private var isTyping: Bool

    /// `showAlertOnAppear` is only for the "Alert" preview.
    init(showAlertOnAppear: Bool = false) {
        _showAlert = State(initialValue: showAlertOnAppear)
    }

    private var trimmedTopic: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var hasChanges: Bool {
        trimmedTopic != store.topic || duration != store.duration
    }

    var body: some View {
        VStack(alignment: .leading) {
            GoalForm(topic: $topic, duration: $duration, focused: $isTyping)
                .padding(.top, 24)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Learning Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: save) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.appOrange)
                .disabled(trimmedTopic.isEmpty)
            }
        }
        .alert("Update goal", isPresented: $showAlert) {
            Button("Dismiss", role: .cancel) { }
            Button("Update") {
                store.updateGoal(topic: trimmedTopic, duration: duration)   // streak starts over
                dismiss()
            }
        } message: {
            Text("If you update now, your streak will start over.")
        }
        .onAppear {
            guard !loaded else { return }
            topic = store.topic
            duration = store.duration
            loaded = true
        }
    }

    private func save() {
        isTyping = false
        if store.status != .active {
            // Coming from Task 3: goal already ended, nothing to lose → start new / same goal.
            store.updateGoal(topic: trimmedTopic, duration: duration)
            dismiss()
        } else if hasChanges {
            showAlert = true          // Task 4 alert
        } else {
            dismiss()
        }
    }
}

#Preview("Task 4 – Update goal") {
    NavigationStack { LearningGoalPage() }
        .environmentObject(LearningStore.sample(learned: 3))
        .preferredColorScheme(.dark)
}

#Preview("Task 4 – Update goal (Alert)") {
    NavigationStack { LearningGoalPage(showAlertOnAppear: true) }
        .environmentObject(LearningStore.sample(learned: 3))
        .preferredColorScheme(.dark)
}
