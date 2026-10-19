import Foundation
import SwiftData

/// One septic system, at one property.
///
/// Written for the homeowner rather than the pumper, because the homeowner is who gets
/// asked for the records: at a property sale, after a county inspection notice, or when a
/// new pumping company wants to know what is buried in the yard. Almost none of that is
/// written down anywhere except a shoebox of receipts.
///
/// The app tracks four separate clocks, because a septic system has four and they do not
/// run together: the tank gets pumped in years, the effluent filter gets cleaned in
/// months, an aerobic unit's service contract runs on its own schedule, and a county
/// inspection has a schedule of its own again. An interval left at zero means the
/// property does not have that duty, and an untracked duty is never reported as overdue.
@Model
final class SepticSystem {
    var id: UUID = UUID()
    var propertyName: String = ""
    var address: String = ""

    // What is actually in the ground. This is the half of the record that gets lost.
    var systemTypeRaw: String = SystemType.conventional.rawValue
    var tankMaterialRaw: String = TankMaterial.concrete.rawValue
    var tankGallons: Double = 0
    var compartments: Int = 1
    var householdSize: Int = 0
    var installedOn: Date? = nil
    var permitNumber: String = ""
    var healthDepartment: String = ""
    /// Where the lids are, in the owner's own words. Every pumper asks, and the answer is
    /// usually "somewhere under the lawn".
    var accessNotes: String = ""
    @Attribute(.externalStorage) var accessPhoto: Data? = nil
    var notes: String = ""

    // The four clocks. Zero means the property does not have this duty.
    var pumpIntervalYears: Int = 3
    var filterIntervalMonths: Int = 0
    var atuServiceIntervalMonths: Int = 0
    var inspectionIntervalMonths: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \ServiceEvent.system)
    var events: [ServiceEvent]? = nil

    @Relationship(deleteRule: .cascade, inverse: \TankCheck.system)
    var checks: [TankCheck]? = nil

    var createdAt: Date = Date()

    init(propertyName: String = "", address: String = "") {
        self.id = UUID()
        self.propertyName = propertyName
        self.address = address
        self.createdAt = .now
    }

    var systemType: SystemType {
        get { SystemType(rawValue: systemTypeRaw) ?? .conventional }
        set { systemTypeRaw = newValue.rawValue }
    }

    var tankMaterial: TankMaterial {
        get { TankMaterial(rawValue: tankMaterialRaw) ?? .concrete }
        set { tankMaterialRaw = newValue.rawValue }
    }

    var sortedEvents: [ServiceEvent] { (events ?? []).sorted { $0.date > $1.date } }
    var sortedChecks: [TankCheck] { (checks ?? []).sorted { $0.date > $1.date } }

    func lastEvent(_ kind: ServiceKind) -> ServiceEvent? {
        sortedEvents.first { $0.kind == kind }
    }

    /// The interval for a duty, in months. Zero means untracked.
    func intervalMonths(for duty: Duty) -> Int {
        switch duty {
        case .pumpOut: return pumpIntervalYears * 12
        case .filterClean: return filterIntervalMonths
        case .atuService: return atuServiceIntervalMonths
        case .inspection: return inspectionIntervalMonths
        }
    }

    func nextDue(_ duty: Duty) -> Date? {
        let months = intervalMonths(for: duty)
        guard months > 0, let last = lastEvent(duty.kind) else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: last.date)
    }

    func status(_ duty: Duty, asOf today: Date = .now) -> DutyStatus {
        guard intervalMonths(for: duty) > 0 else { return .notTracked }
        guard let due = nextDue(duty) else { return .noRecord }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: today),
            to: Calendar.current.startOfDay(for: due)
        ).day ?? 0
        if days < 0 { return .overdue(daysBy: -days) }
        if days <= 60 { return .dueSoon(inDays: days) }
        return .current(inDays: days)
    }

    /// Every duty this property actually has, soonest first.
    func duties(asOf today: Date = .now) -> [(duty: Duty, status: DutyStatus)] {
        Duty.allCases
            .map { ($0, status($0, asOf: today)) }
            .filter { $0.1 != .notTracked }
            .sorted { $0.1.urgency > $1.1.urgency }
    }

    /// What the tank itself says, which can contradict the calendar.
    ///
    /// Two published rules, each applied only when the figures it needs were written down.
    /// A tank measured without its liquid depth yields no fraction, and the app does not
    /// guess one: a made-up denominator would turn a real measurement into a wrong answer.
    var tankVerdict: TankVerdict? {
        guard let check = sortedChecks.first else { return nil }
        return check.verdict
    }

    var headline: String {
        propertyName.isEmpty ? (address.isEmpty ? "My septic system" : address) : propertyName
    }
}

/// Anything that happened to the system, in one shape, because the homeowner's question
/// is "what has been done to this thing" and not "show me the pumping table".
@Model
final class ServiceEvent {
    var id: UUID = UUID()
    var date: Date = Date()
    var kindRaw: String = ServiceKind.pumpOut.rawValue
    var company: String = ""
    var licenseNumber: String = ""
    var technician: String = ""
    var gallonsPumped: Double = 0
    var cost: Double = 0
    var findings: String = ""
    var notes: String = ""
    /// The receipt or the county's form. This is the piece a buyer's agent asks for.
    @Attribute(.externalStorage) var documentPhoto: Data? = nil
    var system: SepticSystem? = nil

    init(date: Date = .now, kind: ServiceKind = .pumpOut) {
        self.id = UUID()
        self.date = date
        self.kindRaw = kind.rawValue
    }

    var kind: ServiceKind {
        get { ServiceKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var day: Date { Calendar.current.startOfDay(for: date) }
}

/// A measurement of what is in the tank.
@Model
final class TankCheck {
    var id: UUID = UUID()
    var date: Date = Date()
    var checkedBy: String = ""
    var scumInches: Double = 0
    var sludgeInches: Double = 0
    /// Total liquid depth of the tank. Without it there is no fraction to compute.
    var liquidDepthInches: Double = 0
    /// Clearances an inspector writes down: how far the scum sits above, and the sludge
    /// below, the bottom of the outlet baffle.
    var scumClearanceInches: Double = 0
    var sludgeClearanceInches: Double = 0
    var notes: String = ""
    var system: SepticSystem? = nil

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
    }

    /// Solids as a fraction of liquid depth, or nil when the depth was not recorded.
    var solidsFraction: Double? {
        guard liquidDepthInches > 0, scumInches + sludgeInches > 0 else { return nil }
        return (scumInches + sludgeInches) / liquidDepthInches
    }

    var verdict: TankVerdict {
        var reasons: [String] = []
        // EPA and state extension guidance: pump when the bottom of the scum layer is
        // within three inches of the bottom of the outlet baffle, or the top of the
        // sludge within twelve inches of it.
        if scumClearanceInches > 0, scumClearanceInches <= 3 {
            reasons.append("scum is within \(short(scumClearanceInches)) in of the outlet baffle (pump at 3 in)")
        }
        if sludgeClearanceInches > 0, sludgeClearanceInches <= 12 {
            reasons.append("sludge is within \(short(sludgeClearanceInches)) in of the outlet baffle (pump at 12 in)")
        }
        if let fraction = solidsFraction, fraction >= 1.0 / 3.0 {
            reasons.append("solids fill \(Int((fraction * 100).rounded()))% of the tank depth (pump at a third)")
        }
        return TankVerdict(pumpIndicated: !reasons.isEmpty, reasons: reasons,
                           measured: scumInches + sludgeInches + scumClearanceInches + sludgeClearanceInches > 0)
    }

    private func short(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

struct TankVerdict {
    let pumpIndicated: Bool
    let reasons: [String]
    /// False when nothing usable was written down, which is different from "fine".
    let measured: Bool
}

// MARK: - Vocabulary

enum Duty: String, CaseIterable, Identifiable {
    case pumpOut, filterClean, atuService, inspection
    var id: String { rawValue }

    var kind: ServiceKind {
        switch self {
        case .pumpOut: return .pumpOut
        case .filterClean: return .filterCleaned
        case .atuService: return .atuService
        case .inspection: return .inspection
        }
    }

    var name: String {
        switch self {
        case .pumpOut: return "Tank pumping"
        case .filterClean: return "Effluent filter cleaning"
        case .atuService: return "Aerobic unit service"
        case .inspection: return "Inspection"
        }
    }

    var why: String {
        switch self {
        case .pumpOut:
            return "Solids that reach the outlet go out to the drainfield, and a ruined drainfield is the expensive failure. The EPA's general guidance for a household system is every three to five years; a garbage disposal, more people than the tank was sized for, or a water softener draining to the tank all shorten it. Your county or your pumper may set a shorter interval, and theirs wins."
        case .filterClean:
            return "A clogged effluent filter backs sewage up into the house. It is a ten-minute job most owners can do themselves, usually once a year."
        case .atuService:
            return "Aerobic treatment units are mechanical, and most states require a service contract with a licensed maintenance provider. Missing visits is a permit problem as well as a maintenance one."
        case .inspection:
            return "Some counties require a periodic inspection, and most states require one at the sale of the property."
        }
    }

    var symbol: String {
        switch self {
        case .pumpOut: return "arrow.up.bin"
        case .filterClean: return "line.3.horizontal.decrease.circle"
        case .atuService: return "wind"
        case .inspection: return "checklist"
        }
    }
}

enum DutyStatus: Equatable {
    case notTracked
    case noRecord
    case current(inDays: Int)
    case dueSoon(inDays: Int)
    case overdue(daysBy: Int)

    var headline: String {
        switch self {
        case .notTracked: return "Not tracked"
        case .noRecord: return "Nothing recorded yet"
        case .current(let days): return "Due in \(months(days))"
        case .dueSoon(let days): return days == 0 ? "Due today" : "Due in \(days) days"
        case .overdue(let days): return "Overdue by \(months(days))"
        }
    }

    private func months(_ days: Int) -> String {
        if days < 60 { return "\(days) days" }
        let m = days / 30
        if m < 24 { return "\(m) months" }
        return String(format: "%.1f years", Double(days) / 365.0)
    }

    /// Sort key: the thing most likely to cost money first.
    var urgency: Int {
        switch self {
        case .overdue: return 4
        case .dueSoon: return 3
        case .noRecord: return 2
        case .current: return 1
        case .notTracked: return 0
        }
    }

    var needsAttention: Bool {
        switch self {
        case .overdue, .dueSoon, .noRecord: return true
        default: return false
        }
    }
}

enum ServiceKind: String, CaseIterable, Identifiable {
    case pumpOut, inspection, filterCleaned, atuService, repairWork, alarm, drainfield, other
    var id: String { rawValue }

    var name: String {
        switch self {
        case .pumpOut: return "Tank pumped"
        case .inspection: return "Inspection"
        case .filterCleaned: return "Effluent filter cleaned"
        case .atuService: return "Aerobic unit service"
        case .repairWork: return "Repair"
        case .alarm: return "Alarm"
        case .drainfield: return "Drainfield observation"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .pumpOut: return "arrow.up.bin.fill"
        case .inspection: return "checklist"
        case .filterCleaned: return "line.3.horizontal.decrease.circle.fill"
        case .atuService: return "wind"
        case .repairWork: return "wrench.and.screwdriver.fill"
        case .alarm: return "bell.badge.fill"
        case .drainfield: return "leaf.fill"
        case .other: return "doc.text"
        }
    }

    /// What to write down, so the record is worth something years later.
    var hint: String {
        switch self {
        case .pumpOut: return "Company, its licence number, and gallons removed."
        case .inspection: return "Who inspected it and what they found."
        case .filterCleaned: return "A line saying it was rinsed is enough."
        case .atuService: return "Contract visits: the provider and what was serviced."
        case .repairWork: return "What broke, what was replaced, what it cost."
        case .alarm: return "When it sounded, and what cleared it."
        case .drainfield: return "Wet ground, odour, lush grass over the lines, slow drains indoors."
        case .other: return ""
        }
    }

    var countsAsWork: Bool { self != .alarm && self != .drainfield }
}

enum SystemType: String, CaseIterable, Identifiable {
    case conventional, chamber, pressure, mound, sandFilter, aerobic, cesspool, unknown
    var id: String { rawValue }

    var name: String {
        switch self {
        case .conventional: return "Conventional gravity"
        case .chamber: return "Chamber"
        case .pressure: return "Pressure distribution"
        case .mound: return "Mound"
        case .sandFilter: return "Sand filter"
        case .aerobic: return "Aerobic treatment unit"
        case .cesspool: return "Cesspool or seepage pit"
        case .unknown: return "Not sure"
        }
    }

    /// Whether this type normally carries a service contract, used to suggest the clock.
    var usuallyHasServiceContract: Bool { self == .aerobic }
}

enum TankMaterial: String, CaseIterable, Identifiable {
    case concrete, plastic, fiberglass, steel, unknown
    var id: String { rawValue }
    var name: String { self == .unknown ? "Not sure" : rawValue.capitalized }

    var note: String? {
        self == .steel
            ? "Steel tanks corrode and have a finite life. Most counties will not approve a replacement in steel."
            : nil
    }
}
