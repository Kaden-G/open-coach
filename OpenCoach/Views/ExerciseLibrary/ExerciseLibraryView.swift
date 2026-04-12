import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?

    var filteredExercises: [Exercise] {
        var result = exercises
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            FilterChip(title: category.displayName, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                List(filteredExercises, id: \.id) { exercise in
                    ExerciseCard(exercise: exercise)
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
