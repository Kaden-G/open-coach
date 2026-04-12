import SwiftUI

struct ExerciseDetailView: View {
    let exercise: PlannedExercise
    let currentSet: Int
    let onComplete: () -> Void
    let onSubstitute: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Exercise name
            Text(exercise.exerciseName)
                .font(.title.bold())

            // Set indicator
            Text("Set \(currentSet) of \(exercise.sets)")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Rep or time target
            if exercise.reps > 0 {
                VStack {
                    Text("\(exercise.reps)")
                        .font(.system(size: 72, weight: .black))
                        .foregroundStyle(.orange)
                    Text("reps")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            } else if exercise.durationSeconds > 0 {
                VStack {
                    Text("\(exercise.durationSeconds)s")
                        .font(.system(size: 72, weight: .black))
                        .foregroundStyle(.orange)
                    Text("seconds")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    onComplete()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                // AI-003: "Can't do this exercise" button
                Button {
                    onSubstitute()
                } label: {
                    Text("Can't do this exercise")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}
