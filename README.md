# ParkingApp

An iOS parking app: create an account, register your vehicle, pick a parking lot on the
map, choose how long you want to stay, "pay", and watch a live countdown that you can
extend at any time by paying for more time.

The entire user interface is in **English**.

## Requirements

- Xcode 26 or newer
- iOS 18.0+ simulator or device

## Getting started

```bash
open ParkingApp.xcodeproj
```

Or build and test from the command line:

```bash
xcodebuild -project ParkingApp.xcodeproj -scheme ParkingApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project ParkingApp.xcodeproj -scheme ParkingApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Architecture

SwiftUI + MVVM with a repository layer on top of a pluggable key-value store.
Everything runs locally — there is no backend, and payments are simulated.

```
ParkingApp/
├── App/            App entry point and root navigation
├── Core/           Cross-cutting concerns (errors, persistence)
├── DesignSystem/   Spacing, radius and reusable styles
└── Resources/      Assets
ParkingAppTests/    Unit tests (Swift Testing)
```

### Conventions

- Models are immutable `struct`s; updates return new copies.
- Storage is abstracted behind `KeyValueStore` so features never touch the file system
  directly, and tests use `InMemoryKeyValueStore`.
- Errors surface as `AppError`, which carries user-facing English messages.

## Roadmap

| Part | Scope |
| --- | --- |
| 1 | Project scaffold, design system, persistence layer |
| 2 | Accounts: sign up, sign in, persisted session |
| 3 | Vehicles: car model and license plate |
| 4 | Parking lots on the map |
| 5 | Duration picker and simulated payment |
| 6 | Live countdown and time extension |
| 7 | History, notifications and polish |
