import SwiftUI
import SwiftData

// WRK-004: Custom Workout Builder

struct CustomWorkoutBuilder: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]

    @State private var workoutName = ""
    @State private var selectedExercises: [PlannedExercise] = []
    @State private var showExercisePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Name") {
                    TextField("e.g., Morning Core Blast", text: $workoutName)
                }

                Section("Exercises (\(selectedExercises.count))") {
                    ForEach(Array(selectedExercises.enumerated()), id: \.offset) { index, exercise in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.exerciseName)
                                    .font(.headline)
                                Text("\(exercise.sets) sets × \(exercise.reps > 0 ? "\(exercise.reps) reps" : "\(exercise.durationSeconds)s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        selectedExercises.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        selectedExercises.move(fromOffsets: from, toOffset: to)
                    }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startWorkout()
                    }
                    .disabled(selectedExercises.isEmpty || workoutName.isEmpty)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(exercises: exercises) { exercise in
                    let planned = PlannedExercise(
                        exerciseId: exercise.id,
                        exerciseName: exercise.name,
                        sets: 3,
                        reps: exercise.exerciseType == .reps ? exercise.defaultReps : 0,
                        durationSeconds: exercise.exerciseType == .timed ? exercise.defaultDurationSeconds : 0,
                        restSeconds: exercise.restDurationSeconds,
                        orderIndex: selectedExercises.count
                    )
                    selectedExercises.append(planned)
                }
            }
        }
    }

    private func startWorkout() {
        // Custom workouts are tracked via WorkoutSession with isCustomWorkout=true
        dismiss()
    }
}

struct ExercisePickerView: View {
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filtered: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.id) { exercise in
                Button {
                    onSelect(exercise)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.headline)
                        Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
