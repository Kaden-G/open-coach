import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var fitnessLevel: FitnessLevel = .beginner
    @State private var goal: TrainingGoal = .strength
    @State private var trainingDays: Int = 3
    @State private var injuries: Set<InjuryFlag> = []

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
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
                APIKeyOnboardingView()
                    .tag(4)
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

                if currentStep < totalSteps - 1 {
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

// MARK: - API Key Onboarding Step

struct APIKeyOnboardingView: View {
    @State private var selectedProvider: LLMProviderType = .openAI
    @State private var apiKey = ""
    @State private var isSaved = false
    @State private var isTesting = false
    @State private var testResult: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("AI-Enhanced Coaching")
                .font(.title.bold())

            Text("Optionally add your own API key for smarter, LLM-powered training plans. You can always add or change this later in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            // Provider picker
            Picker("Provider", selection: $selectedProvider) {
                ForEach(LLMProviderType.allCases, id: \.self) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedProvider) { _, _ in
                apiKey = ""
                isSaved = false
                testResult = nil
            }

            // Key input
            VStack(spacing: 12) {
                SecureField("Paste your \(selectedProvider.displayName) API key", text: $apiKey)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isSaved {
                    Label("Key saved securely in Keychain", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(result.contains("Success") ? .green : .red)
                }
            }
            .padding(.horizontal)

            // Actions
            HStack(spacing: 12) {
                Button {
                    saveAndTest()
                } label: {
                    if isTesting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save & Test")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty || isTesting)
            }
            .padding(.horizontal)

            Text("No key? No problem — tap Start Training to use offline rule-based coaching.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top)
    }

    private func saveAndTest() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedKey.isEmpty else { return }

        try? KeychainHelper.save(key: selectedProvider.keychainKey, value: trimmedKey)
        isTesting = true
        testResult = nil

        let config = LLMConfiguration(provider: selectedProvider, apiKey: trimmedKey)
        let client = LLMClient(config: config)

        Task {
            do {
                let response = try await client.send(prompt: "Respond with just the word 'connected'.")
                await MainActor.run {
                    testResult = "Success — connected to \(selectedProvider.displayName)"
                    isSaved = true
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "Error: \(error.localizedDescription)"
                    isSaved = false
                    isTesting = false
                    // Remove bad key
                    KeychainHelper.delete(key: selectedProvider.keychainKey)
                }
            }
        }
    }
}

// MARK: - Injury Selection

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
