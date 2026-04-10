import SwiftUI

struct GoalSelectionView: View {
    @Binding var selected: TrainingGoal

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What's your primary goal?")
                .font(.title.bold())

            VStack(spacing: 12) {
                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                    Button {
                        selected = goal
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: goal.icon)
                                .font(.title2)
                                .frame(width: 40)

                            VStack(alignment: .leading) {
                                Text(goal.displayName)
                                    .font(.headline)
                                Text(descriptionFor(goal))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selected == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selected == goal ? Color.orange.opacity(0.1) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
    }

    private func descriptionFor(_ goal: TrainingGoal) -> String {
        switch goal {
        case .fatLoss: "Burn calories, build lean muscle, improve body composition"
        case .strength: "Build muscle, increase power, get stronger"
        case .endurance: "Improve stamina, cardiovascular fitness, and work capacity"
        }
    }
}
