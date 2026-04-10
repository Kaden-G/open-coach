import SwiftUI

struct WeeklyPlanCard: View {
    let week: TrainingWeek

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Week \(week.weekNumber)")
                    .font(.headline)
                if week.isCurrentWeek {
                    Text("CURRENT")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.orange)
                        .clipShape(Capsule())
                }
                Spacer()
            }

            ForEach(week.days.sorted(by: { $0.dayOfWeek < $1.dayOfWeek })) { day in
                DayRow(day: day)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DayRow: View {
    let day: TrainingDay

    var body: some View {
        HStack {
            Text(day.dayName)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)

            if day.isRestDay {
                Text("Rest")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(day.plannedExercises.map(\.exerciseName).joined(separator: ", "))
                    .font(.caption)
                    .lineLimit(1)
            }

            Spacer()

            if day.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if !day.isRestDay {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
