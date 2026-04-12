import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                DifficultyBadge(difficulty: exercise.difficulty)
            }

            Text(exercise.exerciseDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Instructions (expandable)
            DisclosureGroup("Instructions") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                            Text(instruction)
                                .font(.caption)
                        }
                    }
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty

    var color: Color {
        switch difficulty {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
    }

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}
