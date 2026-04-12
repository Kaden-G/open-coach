import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    if let profile = profiles.first {
                        LabeledContent("Fitness Level", value: profile.fitnessLevel.displayName)
                        LabeledContent("Goal", value: profile.primaryGoal.displayName)
                        LabeledContent("Training Days", value: "\(profile.trainingDaysPerWeek)/week")
                    }
                }

                Section("AI Coach") {
                    NavigationLink {
                        APIKeyConfigView()
                    } label: {
                        HStack {
                            Text("API Key Configuration")
                            Spacer()
                            if LLMConfiguration.current != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            } else {
                                Text("Not configured")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Apple Health") {
                    NavigationLink("Health Settings") {
                        HealthSettingsView()
                    }
                }

                Section("Data") {
                    NavigationLink("Export Data") {
                        DataExportView()
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("License", value: "MIT")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
