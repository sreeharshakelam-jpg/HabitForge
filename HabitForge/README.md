# ⚡ FORGE — Habit Tracker

> Build discipline. Forge your future.

A premium, gamified iOS habit tracker with Apple Watch integration.

---

## Setup in Xcode

### Requirements
- Xcode 15+
- iOS 17+ deployment target
- watchOS 10+ deployment target
- macOS Ventura or later

### Steps

1. **Open Xcode** → File → New → Project
2. Choose **App** (iOS) template
3. Set:
   - Product Name: `HabitForge`
   - Bundle ID: `com.yourname.HabitForge`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 17

4. **Add all files** from `HabitForge/` folder into the Xcode project
5. **Add Watch Target**: File → New → Target → watchOS → Watch App
   - Name: `HabitForgeWatch`
   - Add all files from `HabitForgeWatch/` folder

6. **Add Capabilities**:
   - HealthKit (iOS target)
   - Push Notifications
   - Background Modes → Remote notifications
   - WatchConnectivity (auto-included)

7. **Add Info.plist Keys**:
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>FORGE uses Health data to validate fitness habits and enhance insights.</string>
   <key>NSHealthUpdateUsageDescription</key>
   <string>FORGE writes mindfulness data to Apple Health.</string>
   ```

8. **Build & Run** on simulator or device

---

## Project Structure

```
HabitForge/
├── App/
│   ├── HabitForgeApp.swift          # App entry point
│   └── ContentView.swift             # Main tab view
├── Models/
│   ├── Habit.swift                   # Core habit model
│   ├── UserProfile.swift             # User profile + gamification
│   └── Achievement.swift             # Achievements + daily reports
├── Stores/
│   ├── HabitStore.swift              # Main state management
│   └── GamificationEngine.swift      # Points, XP, achievements
├── Services/
│   ├── NotificationManager.swift     # Smart notifications
│   ├── HealthKitManager.swift        # Apple Health integration
│   └── WatchConnectivityManager.swift # Watch sync
├── Views/
│   ├── Onboarding/                   # 4-step onboarding flow
│   ├── Dashboard/                    # Today view + summaries
│   ├── Habits/                       # Habit list, detail, add
│   ├── Analytics/                    # Charts, insights, scores
│   ├── Achievements/                 # Badges, level, rank
│   └── Profile/                     # Settings, premium
└── Extensions/
    └── DesignSystem.swift            # Colors, typography, components

HabitForgeWatch/
├── App/
│   └── HabitForgeWatchApp.swift
├── Models/
│   └── WatchHabitStore.swift         # Watch state + WC sync
├── Views/
│   └── WatchRootView.swift           # Watch UI
└── Complications/
    └── ForgeComplication.swift       # Watch face complication
```

---

## Features

### Core
- ✅ Personalized habit builder (completion, time-based, duration, quantity, avoidance)
- ✅ Gamification: XP, levels, ranks, streaks, achievements, combos
- ✅ Snooze penalty logic
- ✅ Daily check-in + end-of-day summary
- ✅ Comeback mode for missed days
- ✅ 4-step onboarding with goal selection + suggested habits
- ✅ Analytics dashboard with weekly completion charts
- ✅ Apple Watch companion app
- ✅ Watch complications
- ✅ HealthKit integration (steps, sleep, calories, mindfulness)
- ✅ Smart notification system with action buttons
- ✅ Achievement library (30+ achievements)
- ✅ Premium tier design

### Gamification System
| Action | Points | XP |
|--------|--------|----|
| Complete (Easy) | 10 | 5 |
| Complete (Medium) | 25 | 15 |
| Complete (Hard) | 50 | 30 |
| Complete (Elite) | 100 | 60 |
| Early completion bonus | +20% | +20% |
| Streak bonus (30d) | +50% | +50% |
| Perfect day bonus | +50% | +50% |
| Snooze penalty | -15%/snooze | — |
| Combo (2x/3x/4x/5x) | +10/25/40/50% | same |

### Ranks (by Level)
- 🌱 Novice (1)
- ⚡ Apprentice (5)
- 🔥 Disciple (10)
- ⚔️ Warrior (20)
- 🏆 Champion (35)
- 💎 Master (50)
- 👑 Grandmaster (75)
- 🌟 Legend (100)
- 🔱 FORGE (150)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| State | @Observable / ObservableObject |
| Storage | UserDefaults (JSON encoded) |
| Cloud Sync | CloudKit (future) |
| Health | HealthKit |
| Watch | WatchConnectivity |
| Notifications | UserNotifications |
| Haptics | UIFeedbackGenerator |

---

## Design System

**Colors:**
- Background: `#060609`
- Surface: `#0E0E18`
- Card: `#12121E`
- Accent: `#7C3AED` (Electric Violet)
- Success: `#10B981` (Emerald)
- Warning: `#F59E0B` (Amber)
- Error: `#EF4444` (Red)

**Typography:** SF Pro Rounded (system, .rounded design)

**Design language:** Dark-first, glass morphism cards, gradient accents, glow effects

---

## Roadmap

### MVP (Current)
- [x] Core habit CRUD
- [x] Gamification engine
- [x] Apple Watch app
- [x] Notifications
- [x] Analytics
- [x] Onboarding

### v1.1
- [ ] CloudKit sync
- [ ] Widget support
- [ ] Siri shortcuts
- [ ] Import/export habits

### v2.0
- [ ] Social features (friends, leaderboard)
- [ ] AI coaching (via API)
- [ ] Habit streaks on lock screen
- [ ] App Store submission

---

## App Name Ideas

1. **FORGE** — "Build discipline. Forge your future." *(recommended)*
2. **CHAIN** — "Don't break the chain"
3. **VOLT** — Premium, electric, daily voltage
4. **APEX** — Peak performance habit tracker
5. **RITUAL** — Build powerful daily rituals
6. **GRIT** — Because grit is built daily

---

*Built with ❤️ using SwiftUI*
