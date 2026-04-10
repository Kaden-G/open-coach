import SwiftUI
import SwiftData

@main
struct FreeleticsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Exercise.self,
            TrainingPlan.self,
            TrainingWeek.self,
            TrainingDay.self,
            PlannedExercise.self,
            WorkoutSession.self,
            CompletedExercise.self,
            ExerciseSubstitution.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
