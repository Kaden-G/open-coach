import SwiftUI

struct FitnessLevelView: View {
    @Binding var selected: FitnessLevel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("FREELETICS")
                .font(.system(size: 36, weight: .black))
                .foregroundStyle(.orange)

            Text("What's your fitness level?")
                .font(.title2.bold())

            VStack(spacing: 12) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    Button {
                        selected = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                    .font(.headline)
                                Text(descriptionFor(level))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selected == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selected == level ? Color.orange.opacity(0.1) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
    }

    private func descriptionFor(_ level: FitnessLevel) -> String {
        switch level {
        case .beginner: "New to regular exercise or returning after a long break"
        case .intermediate: "Training consistently for 6+ months"
        case .athlete: "Advanced training experience, pushing limits"
        }
    }
}
