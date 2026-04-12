# CLAUDE.md — Open-Coach Development Instructions

## Project Overview

Open-Coach is a local-first, open-source iOS fitness coaching app (Swift/SwiftUI, iOS 17+, SwiftData).
All core data lives on-device. Optional LLM coaching calls OpenAI or Anthropic with a user-supplied key.

**Stack:** Swift 5.10, SwiftUI, SwiftData, XcodeGen, HealthKit, AVFoundation
**Build:** `brew install xcodegen && xcodegen generate && open OpenCoach.xcodeproj`

---

## Architecture

```
OpenCoach/
├── App/              # Entry point, tab routing, onboarding gate
├── Models/           # SwiftData @Model classes (5 models + enums)
├── Services/
│   ├── CoachEngine/  # Rule-based plan generation, weekly adaptation, exercise substitution
│   ├── LLM/          # OpenAI + Anthropic API clients, prompt templates
│   ├── WorkoutEngine/ # Timer (Date-based, background-safe) + audio cues
│   ├── HealthKit/    # Read HRV/HR/sleep, write workouts
│   └── DataExport/   # JSON export of all user data
├── Utilities/        # Keychain helper, exercise seed data (30 exercises)
├── Views/
│   ├── Onboarding/   # 4-step flow: fitness level → goal → days → injuries
│   ├── Coach/        # Plan display, weekly cards, workout launcher
│   ├── ExerciseLibrary/ # Searchable/filterable exercise browser
│   ├── Workout/      # Session runner, timer, rest periods, post-workout RPE, custom builder
│   ├── Progress/     # Dashboard (streak, RPE avg, weekly activity), history list
│   └── Settings/     # API key config, HealthKit toggles, data export, profile display
└── Resources/        # Assets, entitlements, Info.plist
```

### Data Model Hierarchy

TrainingPlan → TrainingWeek[] → TrainingDay[] → PlannedExercise[]
WorkoutSession → CompletedExercise[]
UserProfile (singleton per device)
Exercise (seeded from ExerciseSeedData, 30 bodyweight exercises)

All parent→child relationships use `@Relationship(deleteRule: .cascade)`.

---

## What Works Today (Verified)

These features have real, complete implementations with business logic and UI:

- **Rule-based coach engine** — Generates 8-12 week plans based on fitness level, goal, training days, and injury flags. Progression capped at 10%/week. Smart day distribution avoids consecutive training days.
- **LLM-enhanced coach engine** — `LLMCoach` sends plan generation prompts via `LLMClient`, parses JSON responses with safe-bounds validation, falls back to rule-based on any failure.
- **Exercise substitution** — Multi-criteria matching: same muscle group, respects injuries, prefers same difficulty, avoids duplicates already in workout.
- **Weekly adaptation algorithm** — `WeeklyAdaptation.adaptNextWeek()` adjusts volume multiplier (0.6–1.5x) based on completion rate and average RPE. Triggered via "Adapt Next Week" button in PlanDetailView.
- **Workout session runner** — Full-screen exercise-by-exercise flow with set tracking, rest timers, exercise substitution mid-workout, and post-workout RPE/notes logging.
- **Workout timer** — Date-based calculation (not cumulative, so survives backgrounding/screen lock). 10Hz display refresh on `.common` RunLoop. Audio cues via system sounds.
- **HealthKit integration** — Reads resting HR, HRV, sleep duration (filters to core/deep/REM). Writes completed workouts as HKWorkout with active energy.
- **JSON data export** — Exports profiles, sessions (with completed exercises), and training plans. Pretty-printed, timestamped filename, shared via UIActivityViewController. Bundled JSON Schema.
- **LLM API client** — Working REST client for both OpenAI (gpt-4o) and Anthropic (claude-sonnet). Bearer/x-api-key auth. Token counting. API key stored in Keychain (WhenUnlockedThisDeviceOnly).
- **Prompt templates** — System prompt + plan generation prompt + weekly adaptation prompt. All specify expected JSON schema for structured LLM output.
- **Onboarding flow** — 4-step wizard that persists UserProfile and seeds exercise data.
- **Exercise library** — Searchable by name, filterable by category. 30 exercises with full metadata.
- **Progress dashboard** — Completed count, streak calculation, average RPE, 7-day activity grid, history list.
- **Custom workout builder** — Name + exercise picker with search, reordering, deletion. Creates PlannedExercise objects.
- **Settings** — API key config with test-connection, HealthKit authorization + toggles, data export, profile summary.
- **12 real tests** — Swift Testing framework. CoachEngine (5), WeeklyAdaptation (3), ExerciseSubstitutor (4). All use `#expect()` with meaningful assertions.

---

## Code Conventions

- **SwiftUI views** use `@Query` for SwiftData reads, `@Environment(\.modelContext)` for writes
- **Services** are plain Swift classes, not actors — they take `ModelContext` as init param
- **Enums** with display names use computed `displayName` properties
- **Error handling** uses typed errors (e.g., `KeychainError`, `LLMError`) — maintain this pattern
- **Tests** use Swift Testing framework (`@Test`, `#expect`), not XCTest
- **Audio** uses `AudioServicesPlaySystemSound` (system sounds, no bundled files)
- **Keychain** access is via `KeychainHelper` with `.whenUnlockedThisDeviceOnly` accessibility
- **HealthKit** queries use 24-hour lookback windows
- **Naming:** Files match their primary type name. Views end in `View`. Services are `*Manager` or `*Coach` or `*Client`.

## Security Considerations

- **API keys** stored in iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — good baseline. Not synced across devices.
- **LLM output parsing:** All fields validated against safe bounds. Exercise IDs checked against seed data, rep counts within sane ranges (1–100), week counts match plan constraints. (OWASP LLM Top 10 — LLM01, LLM02)
- **HealthKit data** stays on-device. Read permissions are granular (HR, HRV, sleep only). Write is workout-type only.
- **No analytics, no tracking, no network calls** except user-initiated LLM API calls with user-supplied keys.
- **POAM-001:** If camera/form analysis is implemented, frame data must never leave the device. Vision framework processing should use `VNImageRequestHandler` with no persistence layer. Document data flow explicitly.
