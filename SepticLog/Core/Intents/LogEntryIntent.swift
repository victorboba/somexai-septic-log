import AppIntents
import Foundation

/// "Log an entry in <App>" from Siri, Spotlight or the Shortcuts app. Opens the app straight to a new entry.
struct LogEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Log an Entry"
    static var description = IntentDescription("Opens the app ready to record a pumping, inspection or repair.")
    static var openAppWhenRun = true

    static let pendingKey = "intent.openNewEntry"

    func perform() async throws -> some IntentResult {
        WidgetSnapshot.defaults.set(true, forKey: Self.pendingKey)
        return .result()
    }
}

struct SepticLogShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogEntryIntent(),
            phrases: ["Record service in \(.applicationName)", "Log a pumping in \(.applicationName)"],
            shortTitle: "Record Service",
            systemImageName: "plus.circle"
        )
    }
}
