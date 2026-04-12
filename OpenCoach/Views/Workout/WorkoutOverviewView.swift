import SwiftUI

struct WorkoutOverviewView: View {
    let plannedExercises: [PlannedExercise]
    let planWeekNumber: Int?
    let planDayOfWeek: Int?

    @Environment(\.dismiss) private var dismiss
    @State private var showRunner = false

    private let secondsPerRep: Double = 3.0
    private let transitionSeconds: Int = 30

    private var title: String {
        if let week = planWeekNumber, let day = planDayOfWeek {
            let formatter = DateFormatter()
            let dayIndex = day - 1
            let dayName = dayIndex >= 0 && dayIndex < formatter.weekdaySymbols.count
                ? formatter.weekdaySymbols[dayIndex]
                : "Day \(day)"
            return "Week \(week) — \(dayName)"
        }
        return "Workout"
    }

    private var estimatedDurationSeconds: Int {
        var total: Double = 0
        for exercise in plannedExercises {
            let sets = Double(exercise.sets)
            if exercise.reps > 0 {
                total += sets * (Double(exercise.reps) * secondsPerRep)
            } else if exercise.durationSeconds > 0 {
                total += sets * Double(exercise.durationSeconds)
            }
            total += (sets - 1) * Double(exercise.restSeconds)
        }
        if plannedExercises.count > 1 {
            total += Double(plannedExercises.count - 1) * Double(transitionSeconds)
        }
        return Int(total)
    }

    private var estimatedDurationText: String {
        let minutes = max(1, (estimatedDurationSeconds + 30) / 60)
        return "~\(minutes) min"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header card
                        VStack(spacing: 12) {
                            Text(title)
                                .font(.title2.bold())

                            HStack(spacing: 24) {
                                Label("\(plannedExercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                                Label(estimatedDurationText, systemImage: "clock")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Exercise list
                        ForEach(Array(plannedExercises.enumerated()), id: \.offset) { index, exercise in
                            ExerciseOverviewRow(exercise: exercise, orderNumber: index + 1)
                        }
                    }
                    .padding()
                }

                // Start button
                Button {
                    showRunner = true
                } label: {
                    Text("Start Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding()
            }
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showRunner) {
                WorkoutSessionView(
                    plannedExercises: plannedExercises,
                    planWeekNumber: planWeekNumber,
                    planDayOfWeek: planDayOfWeek
                )
            }
        }
    }
}

private struct ExerciseOverviewRow: View {
    let exercise: PlannedExercise
    let orderNumber: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(orderNumber)")
                .font(.headline)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.body.weight(.medium))

                HStack(spacing: 12) {
                    if exercise.reps > 0 {
                        Text("\(exercise.sets) × \(exercise.reps) reps")
                    } else if exercise.durationSeconds > 0 {
                        Text("\(exercise.sets) × \(exercise.durationSeconds)s")
                    }

                    Text("\(exercise.restSeconds)s rest")
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
