# Septic Tank Service Log

A record of a septic system: what is in the ground, who has pumped or serviced it, and what is coming due. It is for homeowners who need the history ready for a buyer's agent or the county.

One of a set of niche iPhone apps built from a shared SwiftUI template ([somexai-ios-template](https://github.com/victorboba/somexai-ios-template)). It was never released on the App Store; the code is here for anyone to use. The other apps are collected in [somexai-ios-apps](https://github.com/victorboba/somexai-ios-apps).

## What it does

- **One property, one timeline.** A standing answer to "is anything coming due" with the history under it. A second property appears only for people who have one.
- **Four clocks, not one.** Pumping runs in years, the effluent filter in months, an aerobic unit on its service contract, and a county inspection on its own schedule. Each is answered by its own kind of event, and an interval left at zero means the property does not have that duty and is never reported as overdue.
- **What is in the ground**: type, tank size and material, compartments, permit number, health department, and where the lids are, with a photo.
- **Measurement, when there is one.** Scum and sludge figures are checked against the published pump-now limits (solids at a third of liquid depth, scum within 3 in and sludge within 12 in of the outlet baffle). Each rule is applied only from figures actually entered; an empty measurement reads as "nothing recorded", not as a pass.
- **The record**: a PDF system record for a sale or an inspection, naming the company and license number behind every visit, and a CSV of every event across every property.
- Widget, receipt photos, and a How do I use this app guide.

## The boundary

The app keeps a record. It does not inspect the system, certify it, or know any county's requirements. Where a county or a pumper sets a shorter interval, that one wins and the owner enters it.

## Privacy

Data stays on the device in SwiftData. There is no account, no analytics and no network access; iCloud sync is off (`iCloudSyncEnabled = false`). CSV and PDF files leave the device only when you share them.

## Build and run

Requirements: Xcode 26 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), and iOS 17 or later.

```bash
xcodegen generate
open SepticLog.xcodeproj
```

Pick the `SepticLog` scheme and an iPhone simulator, then Run.

Tests:

```bash
xcodebuild -scheme SepticLog -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test
```

Paywall: the app has a hard paywall (annual subscription or lifetime purchase). Running from Xcode uses the bundled `Products.storekit` file, so purchases are simulated and free. Debug builds can also skip it with the `-unlock` launch argument or the Debug switch in Settings.

To run on your own device or ship it:

- Set your team in `project.yml` (`DEVELOPMENT_TEAM`).
- Change the `com.example` bundle ID prefix in `project.yml`, both `.entitlements` files and `Products.storekit`.
- Update `supportEmail`, `privacyPolicyURL` and `appStoreID` in `Shared/AppConfig.swift`.

## Notes for developers

- The duty engine is unit-tested: untracked duties, no-record versus overdue, each duty answered by its own event kind, ordering by trouble, the tank rules and the export contents.

## Project layout

- `SepticLog/App/`: app entry point and `RootView`, the single gate (onboarding, paywall, app).
- `SepticLog/Core/`: CSV/PDF export, photo field, StoreKit entitlement store, App Intents, review prompt, sample data, shared UI.
- `SepticLog/Features/`: Home, Help, Onboarding, Paywall, Settings.
- `SepticLog/Models/`: `SepticSystem` and its service events.
- `SepticLogWidget/`: home screen widget reading a snapshot from the App Group.
- `SepticLogTests/`, `SepticLogUITests/`: unit tests and screenshot UI tests.
- `Shared/AppConfig.swift`: everything that changes per app (name, copy, product IDs, links, onboarding, how-to guide).
- App Shortcut: "Record service in Septic Tank Service Log".

## License

MIT. See [LICENSE](LICENSE).
