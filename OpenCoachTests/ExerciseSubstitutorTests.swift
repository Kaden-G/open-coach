import Testing
import Foundation
@testable import OpenCoach

@Suite("ExerciseSubstitutor Tests")
struct ExerciseSubstitutorTests {

    let substitutor = ExerciseSubstitutor()
    let library = ExerciseSeedData.allExercises

    @Test("Finds substitute with same muscle group")
    func sameMuslceGroup() {
        let pushup = library.first { $0.id == "pushup" }!
        let substitute = substitutor.findSubstitute(
            for: pushup,
            in: library,
            excluding: ["pushup"],
            userInjuries: [.none]
        )

        #expect(substitute != nil, "Should find a substitute for push-up")
        #expect(substitute?.id != "pushup", "Substitute should not be the same exercise")

        if let sub = substitute {
            let sharedMuscles = Set(sub.primaryMuscles).intersection(Set(pushup.primaryMuscles))
            #expect(!sharedMuscles.isEmpty, "Substitute should share at least one primary muscle group")
        }
    }

    @Test("Respects injury contraindications")
    func respectsInjuries() {
        let pushup = library.first { $0.id == "pushup" }!
        let substitute = substitutor.findSubstitute(
            for: pushup,
            in: library,
            excluding: ["pushup"],
            userInjuries: [.wrists]
        )

        if let sub = substitute {
            #expect(!sub.contraindicatedInjuries.contains(.wrists),
                    "Substitute should not be contraindicated for wrist injury")
        }
    }

    @Test("Excludes already-used exercises")
    func excludesUsed() {
        let pushup = library.first { $0.id == "pushup" }!
        let allChestIds = Set(library.filter { $0.primaryMuscles.contains(.chest) }.map(\.id))

        let substitute = substitutor.findSubstitute(
            for: pushup,
            in: library,
            excluding: allChestIds,
            userInjuries: [.none]
        )

        // May or may not find a substitute depending on library, but if it does,
        // it shouldn't be in the excluded set
        if let sub = substitute {
            #expect(!allChestIds.contains(sub.id), "Should not return an excluded exercise")
        }
    }

    @Test("Returns nil when no valid substitute exists")
    func noSubstitute() {
        let pushup = library.first { $0.id == "pushup" }!
        let allIds = Set(library.map(\.id))

        let substitute = substitutor.findSubstitute(
            for: pushup,
            in: library,
            excluding: allIds,
            userInjuries: [.none]
        )

        #expect(substitute == nil, "Should return nil when all exercises are excluded")
    }
}
