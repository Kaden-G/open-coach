# Open-Coach — Open Source iOS Fitness Coach

A local-first, open-source iOS fitness coaching app. AI-driven adaptive training plans, bodyweight-first exercise library, offline-capable workout sessions, and Apple Health integration.

**No backend. No accounts. No subscriptions.**

## Features

- **AI Coach Engine** — Rule-based plan generation that works fully offline. When an API key is configured, plan generation is enhanced via LLM (OpenAI or Anthropic) with automatic fallback to rule-based if the call fails.
- **30+ Bodyweight Exercises** — Original exercise library with instructions, muscle groups, and difficulty ratings.
- **Adaptive Training Plans** — 4-12 week plans that adapt weekly based on your completion rate and RPE feedback. One-tap "Adapt Next Week" adjusts volume and intensity using the built-in adaptation algorithm.
- **Workout Timer** — Accurate to ±100ms even during app backgrounding, calls, and screen lock.
- **Apple Health Integration** — Read recovery signals (HRV, resting HR, sleep). Write completed workouts.
- **Data Export** — One-tap JSON export of all your data. Human-readable with a bundled [JSON Schema](Freeletics/Resources/export-schema.json).
- **Privacy by Default** — All data stays on-device. No analytics, no tracking, no third-party data sharing.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.10+

## Setup

### Basic (Offline Mode)

```bash
git clone <repo-url>
cd Freeletics
brew install xcodegen  # if not installed
xcodegen generate
open Freeletics.xcodeproj
```

Build and run on a simulator or device. The app works fully offline with rule-based coaching from the first launch.

### With AI Enhancement (Optional)

1. Build and run the app
2. Go to **Settings > API Key Configuration**
3. Select your provider (OpenAI or Anthropic)
4. Paste your API key
5. The coach engine will now use LLM-enhanced plan generation when available

Your API key is stored in the iOS Keychain and never leaves your device except to call the API you configured.

## Architecture

```
iOS App (Swift / SwiftUI)
├── Views: Onboarding, Coach, Workout, Progress, Settings
├── Services: CoachEngine, LLM, WorkoutEngine, HealthKit, DataExport
├── Models: SwiftData (UserProfile, Exercise, TrainingPlan, WorkoutSession)
└── Storage: SwiftData (on-device), Keychain (secrets), UserDefaults (prefs)
```

All core data lives on-device. Optional AI coaching features may call an external LLM API, but the app degrades gracefully to rule-based plan generation if offline or unconfigured.

## Data Export Format

The one-tap export produces a JSON file with three top-level sections:

- **profile** — Fitness level, goal, training days, injuries, creation date
- **workoutSessions** — Each session with date, duration, RPE, completion status, and per-exercise details (sets, reps, duration, substitution flag)
- **trainingPlans** — Start date, total weeks, goal, status, completion percentage

A full [JSON Schema](Freeletics/Resources/export-schema.json) (draft 2020-12) is included in the repository.

## License

MIT — see [LICENSE](LICENSE).

## Content Authorship

All exercise descriptions and instructions are original. No proprietary content from any fitness company has been used. See [CREDITS.md](CREDITS.md).
