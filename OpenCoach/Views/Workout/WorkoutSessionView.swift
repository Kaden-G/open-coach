import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plannedExercises: [PlannedExercise]
    let planWeekNumber: Int?
    let planDayOfWeek: Int?

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
        self.plannedExercises = plannedExercises
        self.planWeekNumber = planWeekNumber
        self.planDayOfWeek = planDayOfWeek
        self._session = State(initialValue: WorkoutSession(
            planWeekNumber: planWeekNumber,
            planDayOfWeek: planDayOfWeek
        ))
    }

    var currentExercise: PlannedExercise? {
        guard currentIndex < plannedExercises.count else { return nil }
        return plannedExercises[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentIndex), total: Double(plannedExercises.count))
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
                    dismiss()
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

    private func finishWorkout() {
        session.durationSeconds = Int(Date().timeIntervalSince(startTime))
        session.completed = true
        modelContext.insert(session)
        showPostWorkout = true
    }
}
