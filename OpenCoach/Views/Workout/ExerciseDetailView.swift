import SwiftUI

struct ExerciseDetailView: View {
    let exercise: PlannedExercise
    let currentSet: Int
    let onComplete: (Int) -> Void
    let onSubstitute: () -> Void

    @State private var actualReps: Int = 0

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
                VStack(spacing: 8) {
                    Text("Target: \(exercise.reps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        Button { actualReps = max(0, actualReps - 1) } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundStyle(.orange.opacity(0.7))
                        }

                        Text("\(actualReps)")
                            .font(.system(size: 72, weight: .black))
                            .foregroundStyle(.orange)
                            .frame(minWidth: 100)

                        Button { actualReps = min(100, actualReps + 1) } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundStyle(.orange.opacity(0.7))
                        }
                    }

                    Text("reps completed")
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
                    onComplete(exercise.reps > 0 ? actualReps : exercise.durationSeconds)
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

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
        .onAppear {
            actualReps = exercise.reps
        }
        .onChange(of: currentSet) {
            actualReps = exercise.reps
        }
    }
}
