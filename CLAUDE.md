# CLAUDE.md — Open-Coach Development Instructions

## Project Overview

Open-Coach is a local-first, open-source iOS fitness coaching app (Swift/SwiftUI, iOS 17+, SwiftData).
All core data lives on-device. Optional LLM coaching calls OpenAI or Anthropic with a user-supplied key.

**Stack:** Swift 5.10, SwiftUI, SwiftData, XcodeGen, HealthKit, AVFoundation
**Build:** `brew install xcodegen && xcodegen generate && open Freeletics.xcodeproj`

---

## Architecture

```
Freeletics/
├── App/              # Entry point, tab routing, onboarding gate
├── Models/           # SwiftData @Model classes (5 models + enums)
├── Services/
│   ├── CoachEngine/  # Rule-based plan generation, weekly adaptation, exercise substitution
│   ├── LLM/          # OpenAI + Anthropic API clients, prompt templates
│   ├── WorkoutEngine/ # Timer (Date-based, background-safe) + audio cues
│   ├── HealthKit/    # Read HRV/HR/sleep, write workouts
│   └── DataExport/   # JSON export of all user data
├── Utilities/        # Keychain helper, exercise seed data (31 exercises)
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
Exercise (seeded from ExerciseSeedData, 31 bodyweight exercises)

All parent→child relationships use `@Relationship(deleteRule: .cascade)`.

---

## What Works Today (Verified)

These features have real, complete implementations with business logic and UI:

- **Rule-based coach engine** — Generates 8-12 week plans based on fitness level, goal, training days, and injury flags. Progression capped at 10%/week. Smart day distribution avoids consecutive training days.
- **Exercise substitution** — Multi-criteria matching: same muscle group, respects injuries, prefers same difficulty, avoids duplicates already in workout.
- **Weekly adaptation algorithm** — `WeeklyAdaptation.adaptNextWeek()` adjusts volume multiplier (0.6–1.5x) based on completion rate and average RPE. Sophisticated rules (high RPE → reduce, low RPE + high completion → increase, etc.).
- **Workout session runner** — Full-screen exercise-by-exercise flow with set tracking, rest timers, exercise substitution mid-workout, and post-workout RPE/notes logging.
- **Workout timer** — Date-based calculation (not cumulative, so survives backgrounding/screen lock). 10Hz display refresh on `.common` RunLoop. Audio cues via system sounds.
- **HealthKit integration** — Reads resting HR, HRV, sleep duration (filters to core/deep/REM). Writes completed workouts as HKWorkout with active energy.
- **JSON data export** — Exports profiles, sessions (with completed exercises), and training plans. Pretty-printed, timestamped filename, shared via UIActivityViewController.
- **LLM API client** — Working REST client for both OpenAI (gpt-4o) and Anthropic (claude-sonnet). Bearer/x-api-key auth. Token counting. API key stored in Keychain (WhenUnlockedThisDeviceOnly).
- **Prompt templates** — System prompt + plan generation prompt + weekly adaptation prompt. All specify expected JSON schema for structured LLM output.
- **Onboarding flow** — 4-step wizard that persists UserProfile and seeds exercise data.
- **Exercise library** — Searchable by name, filterable by category. 31 exercises with full metadata.
- **Progress dashboard** — Completed count, streak calculation, average RPE, 7-day activity grid, history list.
- **Custom workout builder** — Name + exercise picker with search, reordering, deletion. Creates PlannedExercise objects.
- **Settings** — API key config with test-connection, HealthKit authorization + toggles, data export, profile summary.
- **12 real tests** — Swift Testing framework. CoachEngine (5), WeeklyAdaptation (3), ExerciseSubstitutor (4). All use `#expect()` with meaningful assertions.

---

## Known Gaps: README Claims vs Reality

These are features the README claims or Info.plist declares that are NOT actually implemented.
Each gap is scoped as a discrete work item.

### GAP-1: LLM-Enhanced Plan Generation (Not Wired)

**Resolution:** Created `LLMCoach` service with full LLM→parse→validate→fallback pipeline. CoachPlanView now uses LLMCoach (async) and shows source indicator (brain icon for LLM, gear for rule-based). All LLM output validated: exercise IDs checked against seed data, reps clamped 1-100, sets 1-10, duration 0-300s, rest 10-180s. Unknown exercise IDs silently skipped (OWASP LLM01). RESOLVED

---

### GAP-2: Weekly Adaptation Has No Trigger

**Resolution:** Added "Adapt Next Week" button to PlanDetailView. Visible when current week has completed sessions and hasn't been adapted yet (idempotency via `completionRate == nil` check). Shows confirmation alert with completion rate and average RPE. RESOLVED

---

### GAP-3: Camera / Form Analysis (Declared but Zero Code)

**What exists:** Info.plist declares `NSCameraUsageDescription`: "Freeletics uses your camera for optional real-time form analysis during exercises. No video is stored or transmitted."
**What's missing:** No camera code, no Vision framework import, no pose estimation, nothing.

**Resolution:** Removed `NSCameraUsageDescription` from Info.plist. Form analysis is a future roadmap item. RESOLVED

---

### GAP-4: Background Tasks (Registered but Not Scheduled)

**What exists:** Info.plist declares two `BGTaskSchedulerPermittedIdentifiers`:
- `com.freeletics.planRecalculation`
- `com.freeletics.healthSync`

**Resolution:** Removed dead `BGTaskSchedulerPermittedIdentifiers` and unused `fetch`/`processing` background modes from Info.plist. Weekly adaptation is triggered via UI button (GAP-2). HealthKit sync is on-demand. Background tasks are a future enhancement if needed. RESOLVED

---

### GAP-5: Export Schema Documentation

**What the README says:** "Human-readable, schema-documented."
**What exists:** JSONExporter produces well-structured, pretty-printed JSON with clear key names.
**Resolution:** Created `Resources/export-schema.json` (JSON Schema draft 2020-12) and added export format section to README. RESOLVED

---

### GAP-6: Exercise Count Mismatch

**README said:** "30 Bodyweight Exercises"
**Reality:** ExerciseSeedData.swift defines exactly 30 exercises — the count was correct.

**Fix:** Updated README to say "30+ Bodyweight Exercises" for future-proofing. RESOLVED

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
- **LLM output parsing** (when wired up): Must validate all fields against safe bounds. Do not blindly persist LLM-generated exercise plans without checking exercise IDs exist in seed data, rep counts are within sane ranges (1–100), and week counts match plan constraints. (OWASP LLM Top 10 — LLM01, LLM02)
- **HealthKit data** stays on-device. Read permissions are granular (HR, HRV, sleep only). Write is workout-type only.
- **No analytics, no tracking, no network calls** except user-initiated LLM API calls with user-supplied keys.
- **POAM-001:** If camera/form analysis is implemented, frame data must never leave the device. Vision framework processing should use `VNImageRequestHandler` with no persistence layer. Document data flow explicitly.
- **POAM-002:** Background task handlers must not make network calls with user API keys without explicit user consent. Plan recalculation should be rule-based only in background context.

## Priority Order for Gap Remediation

1. **GAP-6** — Fix exercise count in README (5 min)
2. **GAP-3 Option A** — Remove camera permission claim (10 min)
3. **GAP-5** — Add export schema doc (1-2 hours)
4. **GAP-2** — Wire weekly adaptation trigger (2-4 hours)
5. **GAP-1** — Wire LLM-enhanced coaching path (4-8 hours)
6. **GAP-4** — Background tasks: implement or remove (2-4 hours, or 10 min to remove)
7. **GAP-3 Option B** — Camera form analysis (weeks — backlog item, not sprint work)
