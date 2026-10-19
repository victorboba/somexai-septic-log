import Foundation
import SwiftData

/// Debug fixtures: a system with a real history and one duty slipping, because an empty
/// timeline shows nothing about what the app is for.
enum SampleData {
    static func insert(into context: ModelContext) {
        let system = SepticSystem(propertyName: "Home", address: "14 Mill Road")
        system.systemType = .conventional
        system.tankMaterial = .concrete
        system.tankGallons = 1000
        system.compartments = 2
        system.householdSize = 4
        system.permitNumber = "SS-2004-1187"
        system.healthDepartment = "Washington County Health"
        system.installedOn = date(yearsAgo: 21)
        system.accessNotes = "Two lids, 8 ft out from the back corner of the garage, in line with the second fence post."
        system.pumpIntervalYears = 3
        system.filterIntervalMonths = 12
        context.insert(system)

        func event(_ kind: ServiceKind, yearsAgo: Double, company: String = "",
                   license: String = "", gallons: Double = 0, cost: Double = 0,
                   findings: String = "") {
            let e = ServiceEvent(date: date(yearsAgo: yearsAgo), kind: kind)
            e.company = company; e.licenseNumber = license
            e.gallonsPumped = gallons; e.cost = cost; e.findings = findings
            e.system = system
            context.insert(e)
        }

        event(.pumpOut, yearsAgo: 9.5, company: "Kessler Septic Service", license: "OR-4471",
              gallons: 1000, cost: 385, findings: "Baffles sound. Filter not present at this visit.")
        event(.repairWork, yearsAgo: 7.2, company: "Kessler Septic Service", license: "OR-4471",
              cost: 620, findings: "Outlet baffle replaced; effluent filter fitted.")
        event(.pumpOut, yearsAgo: 6.4, company: "Kessler Septic Service", license: "OR-4471",
              gallons: 980, cost: 410)
        event(.filterCleaned, yearsAgo: 5.1, findings: "Rinsed at the cleanout. Ten minutes.")
        event(.pumpOut, yearsAgo: 3.3, company: "Ridgeline Pumping", license: "OR-5902",
              gallons: 1050, cost: 465, findings: "Scum layer heavy. Suggested a shorter interval.")
        event(.filterCleaned, yearsAgo: 2.9)
        event(.drainfield, yearsAgo: 1.2,
              findings: "Grass noticeably greener over the east line after heavy rain. Dried out within a week.")
        event(.filterCleaned, yearsAgo: 1.4)

        let check = TankCheck(date: date(yearsAgo: 0.05))
        check.checkedBy = "Owner"
        check.scumInches = 6
        check.sludgeInches = 11
        check.liquidDepthInches = 44
        check.system = system
        context.insert(check)

        try? context.save()
    }

    private static func date(yearsAgo: Double) -> Date {
        Date().addingTimeInterval(-yearsAgo * 365.25 * 24 * 3600)
    }
}
