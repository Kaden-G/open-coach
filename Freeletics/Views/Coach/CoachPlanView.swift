import SwiftUI
import SwiftData

struct CoachPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [TrainingPlan]
    @Query private var profiles: [UserProfile]
    @State private var isGenerating = false

    var activePlan: TrainingPlan? {
        plans.first { $0.status == .active }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let plan = activePlan {
                    PlanDetailView(plan: plan)
                } else {
                    NoPlanView(isGenerating: $isGenerating) {
                        generatePlan()
                    }
                }
            }
            .navigationTitle("Coach")
        }
    }

    private func generatePlan() {
        guard let profile = profiles.first else { return }
        isGenerating = true

        let exercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let coach = RuleBasedCoach()
        let plan = coach.generatePlan(profile: profile, exercises: exercises)
        modelContext.insert(plan)

        isGenerating = false
    }
}

struct NoPlanView: View {
    @Binding var isGenerating: Bool
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run.circle")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Ready to start?")
                .font(.title.bold())

            Text("Generate your personalized training plan based on your fitness profile.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button {
                onGenerate()
            } label: {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Generate My Plan")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(isGenerating)

            Spacer()
        }
    }
}

struct PlanDetailView: View {
    let plan: TrainingPlan
    @State private var selectedDay: TrainingDay?
    @State private var showWorkout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Plan header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Week \(plan.currentWeekNumber) of \(plan.totalWeeks)")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(plan.completionPercentage * 100))%")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    ProgressView(value: plan.completionPercentage)
                        .tint(.orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Current week
                if let week = plan.currentWeek {
                    WeeklyPlanCard(week: week) { day in
                        selectedDay = day
                        showWorkout = true
                    }
                }

                // All weeks
                ForEach(plan.weeks.sorted(by: { $0.weekNumber < $1.weekNumber })) { week in
                    if week.weekNumber != plan.currentWeekNumber {
                        WeeklyPlanCard(week: week) { day in
                            selectedDay = day
                            showWorkout = true
                        }
                    }
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showWorkout) {
            if let day = selectedDay {
                WorkoutSessionView(
                    plannedExercises: day.plannedExercises.sorted(by: { $0.orderIndex < $1.orderIndex }),
                    planWeekNumber: day.week?.weekNumber,
                    planDayOfWeek: day.dayOfWeek
                )
            }
        }
    }
}
