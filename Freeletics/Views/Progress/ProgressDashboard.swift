import SwiftUI
import SwiftData

struct ProgressDashboard: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var completedSessions: [WorkoutSession] {
        sessions.filter(\.completed)
    }

    var currentStreak: Int {
        guard !completedSessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for session in completedSessions {
            let sessionDay = calendar.startOfDay(for: session.date)
            if sessionDay == checkDate || sessionDay == calendar.date(byAdding: .day, value: -1, to: checkDate) {
                streak += 1
                checkDate = sessionDay
            } else if sessionDay < calendar.date(byAdding: .day, value: -1, to: checkDate)! {
                break
            }
        }
        return streak
    }

    var averageRPE: Double {
        let rpes = completedSessions.compactMap(\.rpe)
        guard !rpes.isEmpty else { return 0 }
        return Double(rpes.reduce(0, +)) / Double(rpes.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(value: "\(completedSessions.count)", label: "Workouts")
                        StatCard(value: "\(currentStreak)", label: "Day Streak")
                        StatCard(value: averageRPE > 0 ? String(format: "%.1f", averageRPE) : "—", label: "Avg RPE")
                    }

                    // Weekly volume chart placeholder
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Week")
                            .font(.headline)
                        WeeklyActivityView(sessions: completedSessions)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Recent workouts
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Workouts")
                            .font(.headline)

                        WorkoutHistoryList(sessions: Array(completedSessions.prefix(10)))
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

struct WeeklyActivityView: View {
    let sessions: [WorkoutSession]

    var body: some View {
        let calendar = Calendar.current
        let today = Date()
        let weekdays = (0..<7).map { offset in
            calendar.date(byAdding: .day, value: -6 + offset, to: today)!
        }

        HStack(spacing: 8) {
            ForEach(weekdays, id: \.self) { date in
                let hasWorkout = sessions.contains { calendar.isDate($0.date, inSameDayAs: date) }
                VStack(spacing: 4) {
                    Circle()
                        .fill(hasWorkout ? Color.orange : Color(.systemGray4))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if hasWorkout {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                    Text(dayLabel(date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
