import Foundation
import WidgetKit

enum WidgetSync {
    /// The Home Screen answers the only question a homeowner has between pump-outs:
    /// is anything coming due, and when.
    static func update(with systems: [SepticSystem]) {
        let pending = systems.flatMap { system in
            system.duties().filter { $0.status.needsAttention }
                .map { (system: system, duty: $0.duty, status: $0.status) }
        }
        let soonest = pending.max { $0.status.urgency < $1.status.urgency }
        var snapshot = WidgetSnapshot()
        snapshot.totalEntries = systems.reduce(0) { $0 + $1.sortedEvents.count }
        snapshot.dueSoon = pending.count
        snapshot.lastEntryTitle = soonest.map { $0.duty.name }
        snapshot.lastEntryDate = soonest.flatMap { $0.system.nextDue($0.duty) }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
