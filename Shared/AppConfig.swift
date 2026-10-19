import Foundation

/// The one file to edit when starting a new app from this template.
/// Everything user-facing that changes per app (name, copy, product IDs, links) lives here.
/// Compiled into both the app and the widget, so keep it free of UIKit/SwiftUI imports.
enum AppConfig {
    // MARK: Identity
    static let appName = "Septic Tank Service Log"
    static let bundleID = "com.example.septic-log"
    static let appGroupID = "group.com.example.septic-log"
    /// Your App Store ID once the app is live. The Rate button stays hidden while it is empty.(the number in the App Store URL).
    static let appStoreID = ""

    // MARK: Sync
    /// Set to true only after enabling iCloud + CloudKit on the App ID (see docs/capabilities.md).
    /// With false, SwiftData stores locally and the app works with no Apple capabilities at all.
    static let iCloudSyncEnabled = false

    // MARK: StoreKit (must match App Store Connect and StoreKit/Products.storekit)
    /// Apple allows only letters, digits, underscores and periods in product IDs, so hyphens in the bundle ID are dropped.
    static let productPrefix = bundleID.replacingOccurrences(of: "-", with: "")
    static let annualProductID = "\(productPrefix).pro.annual"
    static let lifetimeProductID = "\(productPrefix).pro.lifetime"

    // MARK: Links
    static let supportEmail = "support@somexai.com"
    /// Hosted copy of PrivacyPolicyView, one page per app under somexai.com/privacy (somexai_corp repo, scripts/privacy.py).
    static let privacyPolicyURL = URL(string: "https://somexai.com/privacy/septic-log/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: Copy
    /// What the app calls one record. "Entry" for a generic log; "Dose", "Visit", "Inspection" in real apps.
    static let entryNoun = "Record"
    static let entryNounPlural = "Records"
    /// File name stem for exports: "septic-log-2026-09-11.csv".
    static let exportFileStem = "septic-log"

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "house.and.flag", title: "What is in your yard",
                       body: "Tank size, system type, permit number, and where the lids are buried. The half of the record that always gets lost."),
        OnboardingPage(symbol: "calendar.badge.clock", title: "Four clocks, not one",
                       body: "Pumping runs in years, the effluent filter in months, an aerobic unit on its contract. Set only the ones your property has."),
        OnboardingPage(symbol: "doc.text.fill", title: "Ready when someone asks",
                       body: "Every pumping, inspection and repair in one PDF, with the company and licence number that did it. Your data stays on your phone."),
    ]

    static let paywallSymbol = "checkmark.seal.fill"
    static let paywallHeadline = "Unlock \(appName)"
    static let paywallBenefits = [
        "Every property, every service record",
        "A PDF system record for a sale or an inspection",
        "Pumping, filter, aerobic service and inspection reminders",
        "No ads, no account, no tracking",
    ]

    // MARK: How-to guide (Settings → How do I use this app; also the ? button on the home screen)
    static let howToIntro = "Four steps. The first one takes the longest, and only happens once."
    static let howTo: [HowToStep] = [
        HowToStep(symbol: "house.and.flag", title: "Describe the system",
                  body: "Tap Set up my system and fill in what you know: type, tank size, permit number, and where the lids are. Leave anything you do not know blank — a partial record still beats none, and you can add to it after the next pumping.",
                  tip: "Photograph the lid location with something permanent in frame, like a fence post. Future you, standing in the snow, will be grateful."),
        HowToStep(symbol: "calendar.badge.clock", title: "Set the intervals you actually have",
                  body: "Pumping is set to every 3 years to start. If you have an effluent filter, an aerobic unit, or a county inspection schedule, turn those on too. Leave the rest off — an interval you do not set is never reported as overdue."),
        HowToStep(symbol: "plus.circle", title: "Record what happens",
                  body: "Tap + and pick what it was: pumped, inspected, filter cleaned, repaired, or an alarm. Add the company and its licence number, and photograph the receipt. That photograph is the part a buyer's agent asks for.",
                  tip: "Say \"Record service in \(appName)\" to Siri to jump straight here."),
        HowToStep(symbol: "square.and.arrow.up", title: "Produce the record",
                  body: "Tap the share icon and choose System record for the PDF, or CSV for a spreadsheet. Send it by Mail, AirDrop it, or save it to Files."),
        HowToStep(symbol: "ruler", title: "Measure the tank, if you want to",
                  body: "Optional. When the tank is open, record the scum and sludge figures under Measure the tank. The app compares them with the published pump-now limits — but only using figures you actually entered, so a missing measurement never turns into a guess."),
    ]

    /// Display prices used only by DEBUG screenshot runs (`-mockPrices`). Keep in sync with StoreKit/Products.storekit.
    static let mockPrices = (annual: "$4.99", lifetime: "$9.99")

    // MARK: Behaviour
    /// Ask for an App Store review after this many successful saves (once per app version).
    static let reviewAfterSuccesses = 3
}

struct HowToStep: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
    var tip: String? = nil
}

struct OnboardingPage: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
}
