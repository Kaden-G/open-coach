import SwiftUI
import SwiftData

struct HealthSettingsView: View {
    @Query private var profiles: [UserProfile]
    @State private var healthKitAuthorized = false
    @State private var showingAuthAlert = false

    var profile: UserProfile? { profiles.first }

    var body: some View {
        Form {
            Section {
                Text("Connect Apple Health to personalize your training based on recovery signals. All health data stays on your device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                Button {
                    requestHealthKitAccess()
                } label: {
                    HStack {
                        Text("Connect Apple Health")
                        Spacer()
                        if healthKitAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            if healthKitAuthorized, let profile {
                Section("Recovery Signals") {
                    Toggle("Resting Heart Rate", isOn: Binding(
                        get: { profile.useHeartRateRecovery },
                        set: { profile.useHeartRateRecovery = $0 }
                    ))

                    Toggle("Heart Rate Variability (HRV)", isOn: Binding(
                        get: { profile.useHRV },
                        set: { profile.useHRV = $0 }
                    ))

                    Toggle("Sleep Duration", isOn: Binding(
                        get: { profile.useSleepData },
                        set: { profile.useSleepData = $0 }
                    ))
                }

                Section {
                    Text("These signals feed into the weekly adaptation loop to modulate training intensity based on your recovery.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Write to Health") {
                LabeledContent("Completed Workouts", value: healthKitAuthorized ? "Enabled" : "Disabled")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Apple Health")
        .onAppear {
            checkHealthKitStatus()
        }
    }

    private func requestHealthKitAccess() {
        Task {
            let authorized = await HealthKitManager.shared.requestAuthorization()
            await MainActor.run {
                healthKitAuthorized = authorized
            }
        }
    }

    private func checkHealthKitStatus() {
        healthKitAuthorized = HealthKitManager.shared.isAuthorized
    }
}
