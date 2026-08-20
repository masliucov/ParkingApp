# ParkingApp

An iOS parking app: create an account, register your vehicle, top up your balance, pick a
spot on the street map near you, choose how long you want to stay, pay, and watch a live
countdown that you can extend at any time by buying more time.

The entire user interface is in **English**.

## What it does

- **Accounts** — sign up and sign in; the session survives closing the app.
- **Vehicles** — register cars by brand and license plate, edit and delete them. The
  brand is picked from a searchable list rather than typed, so it is spelled one way.
  A car that is parked is marked as such in the list, and cannot be deleted until its
  stay ends.
- **Find parking** — a real map centred on you, with parking spots on nearby streets.
  Every spot carries a four-digit code, and the map searches by code or street name —
  including spots parked at before, so a code off an old receipt still finds them. A spot
  holding one of your cars is green and badged with how many, and stays on the map even
  when a search would drop it.
- **Balance** — the money you have sits in the top right of the map, with a `+` that adds
  €5, €10, €20 or €50. Parking is paid out of it, so it goes down as you park.
- **Pay and park** — pick a vehicle and a duration, see the price, start parking. The
  screen shows your balance next to the total, and if it will not cover the stay it says
  how much is missing and offers to add funds without leaving the screen. The same holds
  when buying more time, and the service refuses either one outright if the balance is
  short, so nothing is ever parked for free.
- **Several vehicles at once** — a driver with two cars can have both parked. Each
  vehicle takes one stay at a time; the picker marks the ones already parked.
- **Live countdown** — a card over the map counts down to the second, one per stay,
  soonest to run out first; with more than one car the cards page sideways.
- **Add time** — buy more time; it is added to the end of the stay, never to the moment
  you tap the button.
- **Leave early** — end a stay before the time bought runs out. Nothing is refunded, and
  the history keeps what was paid.
- **Reminders** — a local notification ten minutes before the end, and one when it ends,
  for each stay.
- **History** — every stay, with the street, the plate, how long and how much. Tapping the
  street opens it on the map.

### What is simulated

- **Payments.** No card is ever charged, and adding funds credits the balance out of thin
  air. What is real is the spending: a stay only starts once its price has left the
  balance, and a driver who cannot cover it is turned away.
- **Prices and free spaces.** No source of real parking tariffs exists, so both are
  invented — steadily, so a given spot always shows the same numbers.
- **The spots themselves.** They are random points snapped onto real streets with
  walking directions, not places where parking is known to be legal.

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

The map is the first screen after signing in, with Vehicles, History and Settings a tab
away. Signing out lives at the bottom of Settings.

SwiftUI + MVVM with a repository layer on top of a pluggable key-value store.
Everything runs locally — there is no backend, and payments are simulated.

```
ParkingApp/
├── App/            Entry point, dependency wiring, root navigation
├── Core/           Models, persistence, location, notifications, security
├── DesignSystem/   Spacing, radius, form controls, button styles
├── Features/       Auth · Vehicles · Parking · Home · History · Settings
└── Resources/      Assets
ParkingAppTests/    Unit tests (Swift Testing)
```

Each feature holds its own views, view models, services and repositories. Services take
their dependencies through the initialiser, so tests build them over
`InMemoryKeyValueStore` and never touch the disk.

### Conventions

- Models are immutable `struct`s; updates return new copies.
- Storage is abstracted behind `KeyValueStore` so features never touch the file system
  directly, and tests use `InMemoryKeyValueStore`.
- Errors surface as `AppError` and `AuthError`, which carry user-facing English messages.
- Anything a spot has to keep between launches — its price, its free spaces, its
  four-digit code — is folded out of its street and position with `StableHash`, because
  `String.hashValue` is salted per process and would change them on every launch.
- Timestamps are created with `Date.storageNow()`. Stored files use ISO 8601, which keeps
  whole seconds only, so values in memory stay equal to the ones read back from disk.

### Security note

Accounts live on this device. Passwords are never stored in plain text: each account gets
a random 256-bit salt and only the SHA-256 digest of salt + password is kept. Sign in
reports an unknown email exactly like a wrong password, so the app never reveals which
addresses are registered.

That is enough for a device-local app, but not for a real product: a shipping app must
verify credentials on a backend and use a deliberately slow hash such as PBKDF2, scrypt
or Argon2, because SHA-256 is fast enough to make offline brute force cheap.

### Money

Amounts are `Decimal`, built from whole cents with `Decimal.cents(_:)`. Writing `0.83`
directly goes through `Double` on the way to `Decimal` and lands on 0.8299999999999997952,
which is close enough to look right and wrong enough to fail a comparison.

A balance is one `Wallet` per account, and like every other model it is never edited in
place: adding money or paying for a stay returns a new one. `ParkingSessionService` takes
the price out of the balance before it writes the stay, and puts it back if that write
fails, so there is no way to be parked without having paid.

## Testing

188 tests across 21 suites, all written with Swift Testing.

```bash
xcodebuild -project ParkingApp.xcodeproj -scheme ParkingApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Two pieces have no tests, on purpose: `StreetParkingFinder` and `ParkingNotifications`
both talk to system services over the network, so a test would be slow and would fail
without a connection. The logic they depend on — where candidate spots go, and when a
reminder is due — is pure and is covered.
