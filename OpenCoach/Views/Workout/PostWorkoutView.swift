import SwiftUI

// WRK-003: Post-Workout Logging

struct PostWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    let session: WorkoutSession
    let onDismiss: () -> Void

    @State private var rpe: Double = 5
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("Workout Complete!")
                            .font(.title.bold())

                        Text(session.formattedDuration)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Stats
                    HStack(spacing: 24) {
                        StatCard(
                            value: "\(session.completedExercises.count)",
                            label: "Exercises"
                        )
                        StatCard(
                            value: "\(session.totalVolume)",
                            label: "Total Reps"
                        )
                    }

                    // Planned vs Actual breakdown
                    if session.completedExercises.contains(where: { !$0.setRecords.isEmpty }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance")
                                .font(.headline)

                            ForEach(session.completedExercises.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.exerciseId) { exercise in
                                if !exercise.setRecords.isEmpty {
                                    HStack {
                                        Text(exercise.exerciseName)
                                            .font(.subheadline)
                                        Spacer()
                                        let actual = exercise.setRecords.reduce(0) { $0 + $1.actualReps }
                                        let planned = exercise.setRecords.reduce(0) { $0 + $1.plannedReps }
                                        Text("\(actual)/\(planned) reps")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(actual >= planned ? .green : .orange)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // RPE Slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How hard was it?")
                            .font(.headline)
                        HStack {
                            Text("Easy")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $rpe, in: 1...10, step: 1)
                                .tint(.orange)
                            Text("Max")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("RPE: \(Int(rpe))")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.headline)
                        TextField("How did it feel?", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        session.rpe = Int(rpe)
                        session.notes = notes.isEmpty ? nil : notes
                        try? modelContext.save()
                        onDismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.orange)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
