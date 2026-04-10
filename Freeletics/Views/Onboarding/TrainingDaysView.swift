import SwiftUI

struct TrainingDaysView: View {
    @Binding var days: Int

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How many days per week\ncan you train?")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("\(days) days")
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(.orange)

            Stepper("", value: $days, in: 2...6)
                .labelsHidden()
                .scaleEffect(1.5)

            Text(recommendationText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    private var recommendationText: String {
        switch days {
        case 2: "Great for beginners. Quality over quantity."
        case 3: "The sweet spot for most people. Good balance of training and recovery."
        case 4: "Solid commitment. Allows for focused training splits."
        case 5: "High frequency training. Make sure to prioritize sleep and nutrition."
        case 6: "Very high volume. Best suited for experienced athletes."
        default: ""
        }
    }
}
