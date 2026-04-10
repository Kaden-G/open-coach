import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var fitnessLevel: FitnessLevel = .beginner
    @State private var goal: TrainingGoal = .strength
    @State private var trainingDays: Int = 3
    @State private var injuries: Set<InjuryFlag> = []

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(currentStep + 1), total: 4)
                .tint(.orange)
                .padding(.horizontal)
                .padding(.top)

            TabView(selection: $currentStep) {
                FitnessLevelView(selected: $fitnessLevel)
                    .tag(0)
                GoalSelectionView(selected: $goal)
                    .tag(1)
                TrainingDaysView(days: $trainingDays)
                    .tag(2)
                InjurySelectionView(selected: $injuries)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentStep < 3 {
                    Button("Next") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button("Start Training") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .padding()
        }
    }

    private func completeOnboarding() {
        let injuryList = injuries.isEmpty ? [InjuryFlag.none] : Array(injuries)
        let profile = UserProfile(
            fitnessLevel: fitnessLevel,
            primaryGoal: goal,
            trainingDaysPerWeek: trainingDays,
            injuries: injuryList,
            onboardingComplete: true
        )
        modelContext.insert(profile)

        // Seed exercises if not already present
        ExerciseSeedData.seedIfNeeded(context: modelContext)
    }
}

struct InjurySelectionView: View {
    @Binding var selected: Set<InjuryFlag>

    private var selectableFlags: [InjuryFlag] {
        InjuryFlag.allCases.filter { $0 != .none }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Any injuries or limitations?")
                .font(.title.bold())

            Text("We'll avoid exercises that stress these areas.")
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(selectableFlags, id: \.self) { flag in
                    Button {
                        if selected.contains(flag) {
                            selected.remove(flag)
                        } else {
                            selected.insert(flag)
                        }
                    } label: {
                        Text(flag.displayName)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selected.contains(flag) ? Color.orange.opacity(0.2) : Color(.systemGray6))
                            .foregroundStyle(selected.contains(flag) ? .orange : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            if selected.isEmpty {
                Text("No injuries? Great! Just tap Next.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
    }
}
