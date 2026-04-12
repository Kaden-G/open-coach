import SwiftUI
import SwiftData

struct CoachPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [TrainingPlan]
    @Query private var profiles: [UserProfile]
    @State private var isGenerating = false
    @State private var planSource: LLMCoach.Source?

    var activePlan: TrainingPlan? {
        plans.first { $0.status == .active }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let plan = activePlan {
                    VStack(spacing: 0) {
                        if let source = planSource {
                            HStack {
                                Image(systemName: source == .llm ? "brain" : "gearshape.2")
                                    .font(.caption)
                                Text(source.rawValue)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                        }
                        PlanDetailView(plan: plan)
                    }
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

        Task {
            let coach = LLMCoach()
            let result = await coach.generatePlan(profile: profile, exercises: exercises)

            await MainActor.run {
                modelContext.insert(result.plan)
                planSource = result.source
                isGenerating = false
            }
        }
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
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [WorkoutSession]
    @State private var selectedDay: TrainingDay?
    @State private var showWorkout = false
    @State private var showAdaptationAlert = false
    @State private var adaptationMessage = ""

    private var canAdaptNextWeek: Bool {
        guard plan.currentWeekNumber < plan.totalWeeks else { return false }
        guard let currentWeek = plan.currentWeek else { return false }
        let weekSessions = sessions.filter { $0.planWeekNumber == currentWeek.weekNumber && $0.completed }
        return !weekSessions.isEmpty && currentWeek.completionRate == nil
    }

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

                // Adapt next week button
                if canAdaptNextWeek {
                    Button {
                        adaptNextWeek()
                    } label: {
                        Label("Adapt Next Week", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }

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
        .alert("Plan Adapted", isPresented: $showAdaptationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(adaptationMessage)
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

    private func adaptNextWeek() {
        let exercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let adaptation = WeeklyAdaptation()
        adaptation.adaptNextWeek(plan: plan, completedSessions: sessions, exercises: exercises)

        if let currentWeek = plan.currentWeek {
            let rpeText = currentWeek.averageRPE.map { String(format: "%.1f", $0) } ?? "N/A"
            let completionText = currentWeek.completionRate.map { "\(Int($0 * 100))%" } ?? "N/A"
            adaptationMessage = "Next week adjusted based on your performance.\nCompletion: \(completionText) | Avg RPE: \(rpeText)"
        } else {
            adaptationMessage = "Next week has been adjusted based on your performance."
        }
        showAdaptationAlert = true
    }
}
