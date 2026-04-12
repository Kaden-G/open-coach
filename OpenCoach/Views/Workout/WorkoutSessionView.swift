import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let planWeekNumber: Int?
    let planDayOfWeek: Int?

    @State private var exercises: [PlannedExercise]
    @State private var currentIndex = 0
    @State private var currentSet = 1
    @State private var isResting = false
    @State private var session: WorkoutSession
    @State private var startTime = Date()
    @State private var timer = WorkoutTimer()
    @State private var showPostWorkout = false
    @State private var showSubstitution = false
    @State private var currentSetRecords: [SetRecord] = []

    init(plannedExercises: [PlannedExercise], planWeekNumber: Int? = nil, planDayOfWeek: Int? = nil) {
        self.planWeekNumber = planWeekNumber
        self.planDayOfWeek = planDayOfWeek
        self._exercises = State(initialValue: plannedExercises)
        self._session = State(initialValue: WorkoutSession(
            planWeekNumber: planWeekNumber,
            planDayOfWeek: planDayOfWeek
        ))
    }

    var currentExercise: PlannedExercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentIndex), total: Double(exercises.count))
                    .tint(.orange)

                if let exercise = currentExercise {
                    if isResting {
                        RestPeriodView(timer: timer) {
                            isResting = false
                            advanceSet()
                        }
                    } else {
                        ExerciseDetailView(
                            exercise: exercise,
                            currentSet: currentSet,
                            onComplete: { actualReps in completeSet(actualReps: actualReps) },
                            onSubstitute: { showSubstitution = true }
                        )
                    }
                } else {
                    // Workout complete
                    Color.clear.onAppear {
                        finishWorkout()
                    }
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") {
                        finishWorkout()
                    }
                }
            }
            .sheet(isPresented: $showPostWorkout) {
                PostWorkoutView(session: session) {
                    saveAndDismiss()
                }
            }
            .sheet(isPresented: $showSubstitution) {
                if let exercise = currentExercise {
                    SubstitutionPickerView(
                        currentExercise: exercise,
                        allExercisesInWorkout: exercises
                    ) { substitute in
                        performSubstitution(with: substitute)
                    }
                }
            }
            .onAppear {
                AudioCueManager.shared.configureForWorkout()
                startTime = Date()
            }
            .onDisappear {
                AudioCueManager.shared.deactivate()
            }
        }
    }

    private func completeSet(actualReps: Int) {
        guard let exercise = currentExercise else { return }

        let record = SetRecord(
            setNumber: currentSet,
            plannedReps: exercise.reps,
            actualReps: actualReps
        )
        currentSetRecords.append(record)

        if currentSet >= exercise.sets {
            // Exercise complete
            let completed = CompletedExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                completedSets: currentSetRecords.count,
                completedReps: exercise.reps,
                plannedSets: exercise.sets,
                plannedReps: exercise.reps,
                durationSeconds: exercise.durationSeconds,
                orderIndex: currentIndex
            )
            completed.setRecords = currentSetRecords
            session.completedExercises.append(completed)
            AudioCueManager.shared.playSetComplete()

            currentSetRecords = []
            currentSet = 1
            currentIndex += 1
        } else {
            // Start rest period
            isResting = true
            timer.start(durationSeconds: exercise.restSeconds)
        }
    }

    private func advanceSet() {
        currentSet += 1
    }

    private func performSubstitution(with substitute: Exercise) {
        guard let current = currentExercise else { return }

        let replacement = PlannedExercise(
            exerciseId: substitute.id,
            exerciseName: substitute.name,
            sets: current.sets,
            reps: substitute.exerciseType == .reps ? substitute.defaultReps : 0,
            durationSeconds: substitute.exerciseType == .timed ? substitute.defaultDurationSeconds : 0,
            restSeconds: current.restSeconds,
            orderIndex: current.orderIndex
        )

        exercises[currentIndex] = replacement
        currentSet = 1
        currentSetRecords = []
        showSubstitution = false
    }

    private func finishWorkout() {
        guard !showPostWorkout else { return }
        session.durationSeconds = Int(Date().timeIntervalSince(startTime))
        session.completed = currentIndex >= exercises.count
        modelContext.insert(session)
        try? modelContext.save()
        showPostWorkout = true
    }

    private func saveAndDismiss() {
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Substitution Picker

struct SubstitutionPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let currentExercise: PlannedExercise
    let allExercisesInWorkout: [PlannedExercise]
    let onSelect: (Exercise) -> Void

    private var substitutes: [Exercise] {
        let allExercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let injuries = profiles.first?.injuries ?? []
        let excludedIds = Set(allExercisesInWorkout.map(\.exerciseId))

        // Find the full Exercise object for the current exercise
        guard let currentFull = allExercises.first(where: { $0.id == currentExercise.exerciseId }) else {
            return []
        }

        let substitutor = ExerciseSubstitutor()
        // Collect all candidates (not just one random pick)
        let candidates = allExercises.filter { candidate in
            candidate.id != currentFull.id
            && !excludedIds.contains(candidate.id)
            && !Set(candidate.primaryMuscles).intersection(Set(currentFull.primaryMuscles)).isEmpty
            && !candidate.contraindicatedInjuries.contains(where: { injuries.contains($0) })
        }

        return candidates.sorted { a, b in
            // Prefer same difficulty
            let aDiff = abs(a.difficulty.rawValue - currentFull.difficulty.rawValue)
            let bDiff = abs(b.difficulty.rawValue - currentFull.difficulty.rawValue)
            return aDiff < bDiff
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if substitutes.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No alternatives available")
                            .font(.headline)
                        Text("There are no suitable substitutes for this exercise given your profile.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List(substitutes) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                HStack(spacing: 12) {
                                    Text(exercise.category.displayName)
                                    Text(exercise.difficulty.displayName)
                                    Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Substitute Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
