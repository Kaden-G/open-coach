import SwiftUI

struct WorkoutHistoryList: View {
    let sessions: [WorkoutSession]

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(sessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.displayName)
                            .font(.subheadline.bold())
                        Text(session.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(session.formattedDuration)
                            .font(.subheadline.bold())
                        if let rpe = session.rpe {
                            RPEBadge(rpe: rpe)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct RPEBadge: View {
    let rpe: Int

    var color: Color {
        switch rpe {
        case 1...3: .green
        case 4...6: .orange
        case 7...8: .red
        default: .purple
        }
    }

    var body: some View {
        Text("RPE \(rpe)")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }
}
