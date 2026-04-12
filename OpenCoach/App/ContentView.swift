import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first, profile.onboardingComplete {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            CoachPlanView()
                .tabItem {
                    Label("Coach", systemImage: "brain.head.profile")
                }

            ExerciseLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "figure.strengthtraining.traditional")
                }

            ProgressDashboard()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.orange)
    }
}
