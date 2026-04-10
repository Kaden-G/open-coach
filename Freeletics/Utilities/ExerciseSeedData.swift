import Foundation
import SwiftData

struct ExerciseSeedData {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for exercise in allExercises {
            context.insert(exercise)
        }
    }

    static var allExercises: [Exercise] {
        [
            // PUSH
            Exercise(id: "pushup", name: "Push-Up", description: "Standard push-up targeting chest, shoulders, and triceps.", instructions: ["Start in a high plank position", "Lower chest to the ground", "Push back up to starting position"], primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders], category: .push, difficulty: .beginner, defaultReps: 15),

            Exercise(id: "diamond-pushup", name: "Diamond Push-Up", description: "Close-grip push-up emphasizing triceps activation.", instructions: ["Place hands together forming a diamond shape", "Lower chest toward hands", "Push back up"], primaryMuscles: [.triceps], secondaryMuscles: [.chest, .shoulders], category: .push, difficulty: .intermediate, defaultReps: 10),

            Exercise(id: "pike-pushup", name: "Pike Push-Up", description: "Inverted push-up targeting shoulders.", instructions: ["Start in downward dog position", "Bend elbows to lower head toward floor", "Push back up"], primaryMuscles: [.shoulders], secondaryMuscles: [.triceps], category: .push, difficulty: .intermediate, defaultReps: 10, contraindicatedInjuries: [.shoulders, .wrists]),

            Exercise(id: "decline-pushup", name: "Decline Push-Up", description: "Feet-elevated push-up for upper chest emphasis.", instructions: ["Place feet on elevated surface", "Perform push-up with hands on floor", "Keep core tight throughout"], primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .triceps], category: .push, difficulty: .intermediate, defaultReps: 12),

            Exercise(id: "wide-pushup", name: "Wide Push-Up", description: "Wide-grip push-up for chest stretch and activation.", instructions: ["Place hands wider than shoulder width", "Lower chest to the ground", "Push back up"], primaryMuscles: [.chest], secondaryMuscles: [.shoulders], category: .push, difficulty: .beginner, defaultReps: 12),

            Exercise(id: "tricep-dip", name: "Tricep Dip", description: "Bodyweight dip using a chair or bench.", instructions: ["Place hands on edge of sturdy surface behind you", "Lower body by bending elbows", "Push back up to straight arms"], primaryMuscles: [.triceps], secondaryMuscles: [.chest, .shoulders], category: .push, difficulty: .beginner, defaultReps: 12, contraindicatedInjuries: [.shoulders, .wrists]),

            // PULL
            Exercise(id: "superman", name: "Superman Hold", description: "Prone back extension for posterior chain.", instructions: ["Lie face down with arms extended", "Lift arms, chest, and legs off the floor", "Hold briefly, then lower"], primaryMuscles: [.back], secondaryMuscles: [.glutes], category: .pull, difficulty: .beginner, exerciseType: .timed, defaultDurationSeconds: 30, contraindicatedInjuries: [.lowerBack]),

            Exercise(id: "reverse-snow-angel", name: "Reverse Snow Angel", description: "Prone arm sweep for upper back and rear delts.", instructions: ["Lie face down with arms at sides", "Sweep arms overhead in arc while squeezing back", "Return to starting position"], primaryMuscles: [.back], secondaryMuscles: [.shoulders], category: .pull, difficulty: .beginner, defaultReps: 12),

            Exercise(id: "inverted-row", name: "Inverted Row", description: "Horizontal pull using a sturdy table or bar.", instructions: ["Lie under a sturdy table or low bar", "Grip edge and pull chest up", "Lower back down with control"], primaryMuscles: [.back], secondaryMuscles: [.biceps], category: .pull, difficulty: .intermediate, defaultReps: 10),

            Exercise(id: "prone-y-raise", name: "Prone Y-Raise", description: "Face-down arm raise for upper back and shoulders.", instructions: ["Lie face down with arms forming a Y shape", "Raise arms off the floor", "Hold briefly and lower"], primaryMuscles: [.back], secondaryMuscles: [.shoulders], category: .pull, difficulty: .beginner, defaultReps: 12),

            // LEGS
            Exercise(id: "squat", name: "Bodyweight Squat", description: "Fundamental lower body compound movement.", instructions: ["Stand with feet shoulder-width apart", "Lower hips back and down", "Return to standing"], primaryMuscles: [.quads], secondaryMuscles: [.glutes, .hamstrings], category: .legs, difficulty: .beginner, defaultReps: 15, contraindicatedInjuries: [.knees]),

            Exercise(id: "jump-squat", name: "Jump Squat", description: "Explosive squat variation for power development.", instructions: ["Perform a bodyweight squat", "Explode upward into a jump", "Land softly and repeat"], primaryMuscles: [.quads], secondaryMuscles: [.glutes, .calves], category: .legs, difficulty: .intermediate, defaultReps: 10, contraindicatedInjuries: [.knees, .ankles]),

            Exercise(id: "lunge", name: "Forward Lunge", description: "Unilateral leg exercise for strength and balance.", instructions: ["Step forward with one leg", "Lower back knee toward ground", "Push off front foot to return"], primaryMuscles: [.quads], secondaryMuscles: [.glutes, .hamstrings], category: .legs, difficulty: .beginner, defaultReps: 12, contraindicatedInjuries: [.knees]),

            Exercise(id: "reverse-lunge", name: "Reverse Lunge", description: "Backward lunge variation, easier on the knees.", instructions: ["Step backward with one leg", "Lower back knee toward floor", "Return to standing"], primaryMuscles: [.quads], secondaryMuscles: [.glutes], category: .legs, difficulty: .beginner, defaultReps: 12),

            Exercise(id: "bulgarian-split-squat", name: "Bulgarian Split Squat", description: "Rear-foot-elevated single-leg squat.", instructions: ["Place rear foot on elevated surface", "Lower into a single-leg squat", "Drive through front foot to stand"], primaryMuscles: [.quads], secondaryMuscles: [.glutes, .hamstrings], category: .legs, difficulty: .advanced, defaultReps: 8, contraindicatedInjuries: [.knees, .ankles]),

            Exercise(id: "glute-bridge", name: "Glute Bridge", description: "Hip extension exercise targeting glutes.", instructions: ["Lie on back with knees bent", "Drive hips toward ceiling", "Squeeze glutes at top, then lower"], primaryMuscles: [.glutes], secondaryMuscles: [.hamstrings], category: .legs, difficulty: .beginner, defaultReps: 15),

            Exercise(id: "single-leg-glute-bridge", name: "Single-Leg Glute Bridge", description: "Unilateral glute bridge for strength imbalances.", instructions: ["Lie on back, extend one leg", "Drive hips up using planted foot", "Lower with control"], primaryMuscles: [.glutes], secondaryMuscles: [.hamstrings], category: .legs, difficulty: .intermediate, defaultReps: 10),

            Exercise(id: "calf-raise", name: "Calf Raise", description: "Standing calf raise on flat ground or step.", instructions: ["Stand on edge of step or flat ground", "Rise up on toes", "Lower back down slowly"], primaryMuscles: [.calves], category: .legs, difficulty: .beginner, defaultReps: 20, contraindicatedInjuries: [.ankles]),

            Exercise(id: "wall-sit", name: "Wall Sit", description: "Isometric squat hold against a wall.", instructions: ["Lean against wall with feet shoulder-width apart", "Slide down until thighs are parallel to floor", "Hold position"], primaryMuscles: [.quads], secondaryMuscles: [.glutes], category: .legs, difficulty: .beginner, exerciseType: .timed, defaultDurationSeconds: 45, contraindicatedInjuries: [.knees]),

            // CORE
            Exercise(id: "plank", name: "Plank", description: "Isometric core stabilization exercise.", instructions: ["Start in forearm plank position", "Keep body in straight line from head to heels", "Hold position, breathing steadily"], primaryMuscles: [.core], category: .core, difficulty: .beginner, exerciseType: .timed, defaultDurationSeconds: 45),

            Exercise(id: "side-plank", name: "Side Plank", description: "Lateral core stabilization targeting obliques.", instructions: ["Lie on side with forearm on ground", "Lift hips to form straight line", "Hold position"], primaryMuscles: [.core], category: .core, difficulty: .intermediate, exerciseType: .timed, defaultDurationSeconds: 30),

            Exercise(id: "mountain-climber", name: "Mountain Climber", description: "Dynamic core exercise with cardio component.", instructions: ["Start in high plank position", "Drive knees toward chest alternately", "Maintain steady pace"], primaryMuscles: [.core], secondaryMuscles: [.shoulders, .quads], category: .core, difficulty: .beginner, exerciseType: .timed, defaultDurationSeconds: 30),

            Exercise(id: "bicycle-crunch", name: "Bicycle Crunch", description: "Rotational crunch targeting obliques.", instructions: ["Lie on back with hands behind head", "Bring opposite elbow to opposite knee", "Alternate sides in pedaling motion"], primaryMuscles: [.core], category: .core, difficulty: .beginner, defaultReps: 20, contraindicatedInjuries: [.neck, .lowerBack]),

            Exercise(id: "leg-raise", name: "Lying Leg Raise", description: "Lower abdominal focused exercise.", instructions: ["Lie flat on back", "Raise straight legs to 90 degrees", "Lower slowly without touching floor"], primaryMuscles: [.core], category: .core, difficulty: .intermediate, defaultReps: 12, contraindicatedInjuries: [.lowerBack]),

            Exercise(id: "dead-bug", name: "Dead Bug", description: "Anti-extension core exercise for stability.", instructions: ["Lie on back with arms and legs raised", "Extend opposite arm and leg", "Return and alternate sides"], primaryMuscles: [.core], category: .core, difficulty: .beginner, defaultReps: 12),

            Exercise(id: "v-up", name: "V-Up", description: "Full range of motion crunch targeting the entire core.", instructions: ["Lie flat with arms overhead", "Simultaneously raise legs and torso", "Reach hands toward toes"], primaryMuscles: [.core], category: .core, difficulty: .advanced, defaultReps: 10, contraindicatedInjuries: [.lowerBack]),

            // CARDIO
            Exercise(id: "burpee", name: "Burpee", description: "Full-body explosive cardio movement.", instructions: ["Drop into squat, hands on floor", "Jump feet back to plank", "Do a push-up, jump feet forward, jump up"], primaryMuscles: [.fullBody], secondaryMuscles: [.cardio], category: .cardio, difficulty: .intermediate, defaultReps: 10, contraindicatedInjuries: [.wrists, .knees]),

            Exercise(id: "high-knees", name: "High Knees", description: "Running in place with exaggerated knee drive.", instructions: ["Stand tall", "Drive knees up to hip height alternately", "Pump arms and maintain fast pace"], primaryMuscles: [.cardio], secondaryMuscles: [.quads, .core], category: .cardio, difficulty: .beginner, exerciseType: .timed, defaultDurationSeconds: 30),

            Exercise(id: "jumping-jack", name: "Jumping Jack", description: "Classic full-body cardio warm-up exercise.", instructions: ["Stand with feet together, arms at sides", "Jump feet apart while raising arms overhead", "Jump back to start"], primaryMuscles: [.cardio], secondaryMuscles: [.fullBody], category: .cardio, difficulty: .beginner, defaultReps: 25),

            Exercise(id: "skater-jump", name: "Skater Jump", description: "Lateral plyometric for agility and power.", instructions: ["Stand on one leg", "Jump laterally to opposite foot", "Land softly and repeat"], primaryMuscles: [.glutes], secondaryMuscles: [.quads, .cardio], category: .cardio, difficulty: .intermediate, defaultReps: 16, contraindicatedInjuries: [.knees, .ankles]),
        ]
    }
}
