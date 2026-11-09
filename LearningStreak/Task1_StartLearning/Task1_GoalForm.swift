import SwiftUI

// TASK 1 (also reused in Task 4): "I want to learn" + "I want to learn it in a" Week / Month / Year

struct GoalForm: View {
    @Binding var topic: String
    @Binding var duration: GoalDuration
    var focused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("I want to learn")
                    .font(.system(size: 22))
                TextField("Swift", text: $topic)
                    .font(.system(size: 17))
                    .focused(focused)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .padding(.vertical, 8)
                Rectangle()
                    .fill(Color.inputLine)
                    .frame(height: 0.5)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("I want to learn it in a")
                    .font(.system(size: 22))
                HStack(spacing: 8) {
                    ForEach(GoalDuration.allCases) { option in
                        DurationChip(title: option.title, isSelected: option == duration) {
                            withAnimation(.snappy) { duration = option }
                        }
                    }
                }
            }
        }
    }
}

struct DurationChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primaryText : Color.secondaryText)
                .frame(width: 97, height: 48)
                .background(Capsule().fill(isSelected ? Color.appOrange : .clear))
                .glassBackground(Capsule(), tint: isSelected ? .appOrange : nil)
        }
        .buttonStyle(.plain)
    }
}

private struct GoalFormPreview: View {
    @State var topic = ""
    @State var duration: GoalDuration = .week
    @FocusState var focused: Bool
    var body: some View {
        GoalForm(topic: $topic, duration: $duration, focused: $focused)
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground)
    }
}

#Preview("Task 1 – Goal form") {
    GoalFormPreview()
        .preferredColorScheme(.dark)
}
