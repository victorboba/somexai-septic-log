import Testing
import Foundation
import PDFKit
@testable import SepticLog

/// Four clocks, and only the ones the property actually has. The failure this guards
/// against is an app that invents duties — telling an owner with no aerobic unit that
/// their aerobic service is overdue is how a compliance app gets uninstalled.
struct DutyTests {
    private func system(pumpYears: Int = 3, filterMonths: Int = 0,
                        atuMonths: Int = 0, inspectionMonths: Int = 0) -> SepticSystem {
        let s = SepticSystem(propertyName: "Home", address: "14 Mill Road")
        s.pumpIntervalYears = pumpYears
        s.filterIntervalMonths = filterMonths
        s.atuServiceIntervalMonths = atuMonths
        s.inspectionIntervalMonths = inspectionMonths
        return s
    }

    private func add(_ kind: ServiceKind, monthsAgo: Int, to system: SepticSystem) {
        let e = ServiceEvent(date: Calendar.current.date(byAdding: .month, value: -monthsAgo, to: .now)!,
                             kind: kind)
        e.system = system
        system.events = (system.events ?? []) + [e]
    }

    @Test func anIntervalOfZeroIsNotADuty() {
        let s = system(pumpYears: 3)
        #expect(s.status(.atuService) == .notTracked)
        #expect(s.status(.inspection) == .notTracked)
        #expect(s.duties().map(\.duty) == [.pumpOut], "only the duty the property has")
    }

    @Test func aTrackedDutyWithNoEventReadsAsNothingRecorded() {
        let s = system(pumpYears: 3)
        // Not overdue: nobody has said when it was last done, and guessing would be worse.
        #expect(s.status(.pumpOut) == .noRecord)
        #expect(s.nextDue(.pumpOut) == nil)
    }

    @Test func pumpingIsDueAnIntervalAfterTheLastPumping() {
        let s = system(pumpYears: 3)
        add(.pumpOut, monthsAgo: 12, to: s)
        let due = try? #require(s.nextDue(.pumpOut))
        #expect(due != nil)
        if case .current(let days) = s.status(.pumpOut) {
            #expect(days > 600 && days < 760, "roughly two years out")
        } else {
            Issue.record("expected current, got \(s.status(.pumpOut))")
        }
    }

    @Test func overdueCountsFromTheDueDateNotTheLastVisit() {
        let s = system(pumpYears: 3)
        add(.pumpOut, monthsAgo: 48, to: s)   // a year past a three-year interval
        guard case .overdue(let days) = s.status(.pumpOut) else {
            Issue.record("expected overdue, got \(s.status(.pumpOut))"); return
        }
        #expect(days > 330 && days < 400)
    }

    @Test func eachDutyIsAnsweredByItsOwnKindOfEvent() {
        let s = system(pumpYears: 3, filterMonths: 12)
        add(.pumpOut, monthsAgo: 1, to: s)
        // A pumping does not clean the filter, and the app must not pretend it did.
        #expect(s.status(.filterClean) == .noRecord)
        add(.filterCleaned, monthsAgo: 1, to: s)
        if case .current = s.status(.filterClean) {} else {
            Issue.record("filter should be current after a cleaning")
        }
    }

    @Test func dutiesAreOrderedByTrouble() {
        let s = system(pumpYears: 3, filterMonths: 12, inspectionMonths: 36)
        add(.pumpOut, monthsAgo: 1, to: s)        // current
        add(.filterCleaned, monthsAgo: 24, to: s) // a year overdue
        // inspection has no record at all
        let order = s.duties().map(\.duty)
        #expect(order.first == .filterClean, "overdue outranks everything")
        #expect(order.last == .pumpOut, "what is fine goes last")
        #expect(order.count == 3)
    }

    @Test func aDutyInsideSixtyDaysReadsAsDueSoon() {
        let s = system(pumpYears: 0, filterMonths: 12)
        add(.filterCleaned, monthsAgo: 11, to: s)
        guard case .dueSoon = s.status(.filterClean) else {
            Issue.record("expected dueSoon, got \(s.status(.filterClean))"); return
        }
    }

    @Test func anAerobicSystemWithNoContractSetIsStillNotNagged() {
        let s = system(pumpYears: 3)
        s.systemType = .aerobic
        // The type suggests a contract in the editor; it never fabricates one here.
        #expect(s.status(.atuService) == .notTracked)
    }
}

/// The tank can disagree with the calendar. Every rule here is applied only from figures
/// somebody actually wrote down.
struct TankCheckTests {
    private func check(scum: Double = 0, sludge: Double = 0, depth: Double = 0,
                       scumClear: Double = 0, sludgeClear: Double = 0) -> TankCheck {
        let c = TankCheck(date: .now)
        c.scumInches = scum; c.sludgeInches = sludge
        c.liquidDepthInches = depth
        c.scumClearanceInches = scumClear
        c.sludgeClearanceInches = sludgeClear
        return c
    }

    @Test func noLiquidDepthMeansNoFraction() {
        let c = check(scum: 6, sludge: 12)
        #expect(c.solidsFraction == nil, "a denominator nobody measured is not a denominator")
        #expect(!c.verdict.pumpIndicated)
        #expect(c.verdict.measured, "layers were measured, they just do not answer the fraction rule")
    }

    @Test func solidsOverAThirdIndicatePumping() {
        let c = check(scum: 6, sludge: 10, depth: 44)   // 16/44 = 36%
        #expect(c.verdict.pumpIndicated)
        #expect(c.verdict.reasons.contains { $0.contains("36%") })
    }

    @Test func solidsUnderAThirdDoNot() {
        let c = check(scum: 4, sludge: 6, depth: 44)    // 10/44 = 23%
        #expect(!c.verdict.pumpIndicated)
    }

    @Test func theBaffleClearancesAreJudgedSeparately() {
        #expect(check(scumClear: 2).verdict.pumpIndicated, "scum within 3 in of the baffle")
        #expect(!check(scumClear: 8).verdict.pumpIndicated)
        #expect(check(sludgeClear: 9).verdict.pumpIndicated, "sludge within 12 in of the baffle")
        #expect(!check(sludgeClear: 20).verdict.pumpIndicated)
    }

    @Test func anEmptyMeasurementIsNotAPass() {
        let c = check()
        #expect(!c.verdict.measured, "nothing recorded is different from within limits")
        #expect(!c.verdict.pumpIndicated)
    }

    @Test func everyReasonIsGivenNotJustTheFirst() {
        let c = check(scum: 8, sludge: 12, depth: 44, scumClear: 2, sludgeClear: 6)
        #expect(c.verdict.reasons.count == 3)
    }
}

struct ExportTests {
    private func loaded() -> SepticSystem {
        let s = SepticSystem(propertyName: "Home", address: "14 Mill Road")
        s.systemType = .conventional
        s.tankGallons = 1000
        s.permitNumber = "SS-2004-1187"
        s.pumpIntervalYears = 3
        s.filterIntervalMonths = 12
        let pump = ServiceEvent(date: Calendar.current.date(byAdding: .month, value: -48, to: .now)!,
                                kind: .pumpOut)
        pump.company = "Kessler Septic Service"
        pump.licenseNumber = "OR-4471"
        pump.gallonsPumped = 1000
        pump.cost = 385
        pump.system = s
        let repairWork = ServiceEvent(date: Calendar.current.date(byAdding: .month, value: -30, to: .now)!,
                                      kind: .repairWork)
        repairWork.findings = "Outlet baffle replaced"
        repairWork.system = s
        s.events = [pump, repairWork]
        return s
    }

    @Test func csvHasAHeaderAndOneRowPerEvent() throws {
        let text = try String(contentsOf: try CSVExporter.export([loaded()]), encoding: .utf8)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        #expect(lines.count == 3)
        #expect(lines[0].hasPrefix("property,address,system_type"))
    }

    @Test func csvQuotesACompanyNameWithACommaInIt() throws {
        let s = loaded()
        s.sortedEvents.first?.company = "Kessler Septic, Inc."
        let text = try String(contentsOf: try CSVExporter.export([s]), encoding: .utf8)
        #expect(text.contains("\"Kessler Septic, Inc.\""))
    }

    @Test func csvLeavesUnrecordedFiguresBlank() throws {
        let text = try String(contentsOf: try CSVExporter.export([loaded()]), encoding: .utf8)
        // The repair has no gallons and no cost; those must be empty, not zeros.
        let repairRow = try #require(text.split(separator: "\n").first { $0.contains("Repair") })
        #expect(repairRow.contains(",,"))
        #expect(!repairRow.contains(",0,"))
    }

    @Test func thePdfLeadsWithWhatTheSystemIs() throws {
        let url = try PDFExporter.export(loaded())
        let doc = try #require(PDFDocument(url: url))
        let text = (doc.string ?? "").replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        #expect(text.contains("Septic system record"))
        #expect(text.contains("Conventional gravity"))
        #expect(text.contains("SS-2004-1187"))
        #expect(text.contains("1000 gallons"))
    }

    @Test func thePdfNamesTheCompanyAndItsLicence() throws {
        let url = try PDFExporter.export(loaded())
        let doc = try #require(PDFDocument(url: url))
        let text = (doc.string ?? "").replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        #expect(text.contains("Kessler Septic Service · licence OR-4471"))
    }

    @Test func thePdfSaysWhenSomethingIsOverdueRatherThanPrintingATidyPage() throws {
        let url = try PDFExporter.export(loaded())
        let doc = try #require(PDFDocument(url: url))
        let text = (doc.string ?? "").replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        // Padded columns come back out of order from PDFKit, so match the pieces, not
        // their adjacency: the sheet must name both duties and both of their states.
        #expect(text.contains("Tank pumping"))
        #expect(text.contains("Effluent filter cleaning"))
        #expect(text.contains("Overdue by"))
        #expect(text.contains("Nothing recorded yet"))
    }

    @Test func anEmptyHistorySaysSoWithoutShamingAnyone() throws {
        let s = SepticSystem(propertyName: "Cabin", address: "")
        let url = try PDFExporter.export(s)
        let doc = try #require(PDFDocument(url: url))
        let text = (doc.string ?? "").replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        #expect(text.contains("No service has been recorded"))
        #expect(text.contains("still worth more than none"))
    }

    @Test func thePdfDoesNotClaimToInspectAnything() throws {
        let url = try PDFExporter.export(loaded())
        let doc = try #require(PDFDocument(url: url))
        let text = (doc.string ?? "").replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        #expect(text.contains("does not inspect the system, certify it"))
    }
}
