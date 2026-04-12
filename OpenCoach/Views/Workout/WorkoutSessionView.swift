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
                            onComplete: { completeSet() },
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

    private func completeSet() {
        guard let exercise = currentExercise else { return }

        if currentSet >= exercise.sets {
            // Exercise complete
            let completed = CompletedExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                completedSets: exercise.sets,
                completedReps: exercise.reps,
                durationSeconds: exercise.durationSeconds,
                orderIndex: currentIndex
            )
            session.completedExercises.append(completed)
            AudioCueManager.shared.playSetComplete()

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
