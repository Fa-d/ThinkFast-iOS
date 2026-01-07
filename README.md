# ThinkFast iOS

A digital wellbeing app for iOS that helps users reduce excessive app usage through mindful intervention and behavioral change techniques.

## Overview

ThinkFast helps users build healthier digital habits by:
- Setting daily usage goals for apps
- Providing gentle interventions when limits are approached
- Tracking streaks and progress
- Offering insights and analytics

## Project Status

**Phase 1 Complete** - Project foundation established

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ Complete | Project setup, data models, UI foundation |
| Phase 2 | ⏳ Pending | Repository implementations |
| Phase 3 | ⏳ Pending | Domain layer (use cases) |
| Phase 4 | ⏳ Pending | Core services (monitoring, interventions) |
| Phase 5 | ⏳ Pending | Full UI implementation |
| Phase 6 | ⏳ Pending | Advanced features (sync, widgets) |
| Phase 7 | ⏳ Pending | Testing & polish |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

```bash
# Clone or navigate to project
cd /Users/fahad/myLab/XCP/TF/ThinkFast

# Open in Xcode
open ThinkFast.xcodeproj

# Or build with SPM
swift build
```

## Project Structure

```
ThinkFast/
├── App/                    # App entry point & lifecycle
├── Data/                   # Data layer (repositories, database)
│   ├── Local/Database/     # Swift Data models
│   └── Repository/         # Repository implementations
├── Domain/                 # Business logic
│   ├── Model/              # Domain models
│   ├── Repository/         # Repository protocols
│   └── UseCase/            # Use cases
├── Presentation/           # UI layer
│   ├── Common/             # Shared UI components
│   ├── Home/               # Home screen
│   ├── Stats/              # Statistics screen
│   ├── Settings/           # Settings screen
│   ├── Onboarding/         # Onboarding flow
│   └── Auth/               # Authentication screens
└── Core/                   # Core infrastructure
    ├── DI/                 # Dependency injection
    ├── Theme/              # App theming
    └── Util/               # Utilities & extensions
```

## Architecture

Clean Architecture + MVVM

- **Data Layer**: Swift Data + Repository Pattern
- **Domain Layer**: Use Cases + Domain Models
- **Presentation Layer**: SwiftUI + Observable ViewModels
- **Dependency Injection**: Custom DI Container

## Key Technologies

- **SwiftUI** - Modern UI framework
- **Swift Data** - Data persistence (iOS 17+)
- **Family Controls** - Screen Time API
- **Firebase** - Analytics, Auth, Crashlytics
- **Facebook SDK** - Authentication

## Database Schema

| Entity | Description |
|--------|-------------|
| UsageSession | App usage sessions |
| UsageEvent | Individual usage events |
| DailyStats | Daily aggregated statistics |
| Goal | User goals & streaks |
| InterventionResult | Intervention effectiveness |
| StreakRecovery | Streak recovery tracking |
| UserBaseline | First-week baseline |

## Contributing

This is a personal project. Reference the conversion plan:
- [iOS Conversion Plan](/Users/fahad/myLab/XCP/TF/iOS_CONVERSION_PLAN.md)
- [Quick Reference](/Users/fahad/myLab/XCP/TF/QUICK_REFERENCE.md)

## License

Copyright © 2025 ThinkFast. All rights reserved.
