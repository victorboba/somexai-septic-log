import Foundation
import PDFKit
import UIKit

/// The system record.
///
/// This is what the app is for. At a sale, a refinance, or a county notice, somebody asks
/// a homeowner to produce the history of a thing that is buried in their garden, and the
/// honest answer is usually a shoebox. So the sheet leads with what the system *is* —
/// type, tank, permit number, where the lids are — then every event in date order with
/// the company and licence number that did it, and it says plainly where a gap is rather
/// than printing a tidy page that implies nothing was ever needed.
enum PDFExporter {
    static func export(_ system: SepticSystem, asOf today: Date = .now) throws -> URL {
        let pageWidth: CGFloat = 612, pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppConfig.exportFileStem)-\(ISO8601DateFormatter.day.string(from: today)).pdf")

        try renderer.writePDF(to: url) { ctx in
            var y: CGFloat = margin
            ctx.beginPage()

            func line(_ text: String, size: CGFloat = 11, weight: UIFont.Weight = .regular,
                      colour: UIColor = .label, indent: CGFloat = 0, gapAfter: CGFloat = 4) {
                let font = UIFont.systemFont(ofSize: size, weight: weight)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: colour]
                let width = pageWidth - margin * 2 - indent
                let bounding = (text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
                if y + bounding.height > pageHeight - margin { ctx.beginPage(); y = margin }
                (text as NSString).draw(
                    with: CGRect(x: margin + indent, y: y, width: width, height: bounding.height),
                    options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
                y += bounding.height + gapAfter
            }
            func rule(gap: CGFloat = 10) {
                y += gap / 2
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                UIColor.separator.setStroke(); path.lineWidth = 0.5; path.stroke()
                y += gap / 2
            }
            func field(_ label: String, _ value: String) {
                guard !value.isEmpty else { return }
                line("\(label.padding(toLength: 20, withPad: " ", startingAt: 0))\(value)",
                     size: 10, gapAfter: 2)
            }

            line("Septic system record", size: 22, weight: .semibold)
            line(system.headline, size: 12, colour: .secondaryLabel)
            if !system.address.isEmpty && !system.propertyName.isEmpty {
                line(system.address, size: 10, colour: .secondaryLabel)
            }
            rule()

            line("The system", size: 13, weight: .semibold, gapAfter: 6)
            field("Type", system.systemType.name)
            field("Tank", [system.tankGallons > 0 ? "\(short(system.tankGallons)) gallons" : "",
                           system.tankMaterial == .unknown ? "" : system.tankMaterial.name,
                           system.compartments > 1 ? "\(system.compartments) compartments" : ""]
                    .filter { !$0.isEmpty }.joined(separator: ", "))
            if let installed = system.installedOn {
                field("Installed", installed.formatted(date: .long, time: .omitted))
            }
            field("Permit", system.permitNumber)
            field("Health department", system.healthDepartment)
            field("Household", system.householdSize > 0 ? "\(system.householdSize) people" : "")
            field("Access", system.accessNotes)
            rule()

            line("Where it stands", size: 13, weight: .semibold, gapAfter: 6)
            let duties = system.duties(asOf: today)
            if duties.isEmpty {
                line("No maintenance intervals have been set for this property.",
                     size: 10, colour: .secondaryLabel)
            }
            for (duty, status) in duties {
                let colour: UIColor = switch status {
                case .overdue: .systemRed
                case .dueSoon: .systemOrange
                case .noRecord: .secondaryLabel
                default: .label
                }
                var text = "\(duty.name.padding(toLength: 30, withPad: " ", startingAt: 0))\(status.headline)"
                if let due = system.nextDue(duty) {
                    text += "  (\(ISO8601DateFormatter.day.string(from: due)))"
                }
                line(text, size: 10, weight: status.needsAttention ? .semibold : .regular,
                     colour: colour, gapAfter: 2)
            }

            if let check = system.sortedChecks.first {
                let verdict = check.verdict
                if verdict.measured {
                    line("Last measured \(ISO8601DateFormatter.day.string(from: check.date)): "
                         + (verdict.pumpIndicated ? "pumping indicated" : "within the published limits"),
                         size: 10, weight: .semibold,
                         colour: verdict.pumpIndicated ? .systemRed : .systemGreen, gapAfter: 2)
                    for reason in verdict.reasons {
                        line(reason, size: 9, colour: .systemRed, indent: 12, gapAfter: 1)
                    }
                }
            }
            rule()

            line("History", size: 13, weight: .semibold, gapAfter: 6)
            let events = system.sortedEvents
            if events.isEmpty {
                line("No service has been recorded for this system. A record that starts today "
                     + "is still worth more than none.", size: 10, colour: .secondaryLabel)
            }
            for e in events {
                line("\(ISO8601DateFormatter.day.string(from: e.date))   \(e.kind.name)",
                     size: 10, weight: .semibold, gapAfter: 1)
                var parts: [String] = []
                if !e.company.isEmpty { parts.append(e.company) }
                if !e.licenseNumber.isEmpty { parts.append("licence \(e.licenseNumber)") }
                if !e.technician.isEmpty { parts.append(e.technician) }
                if e.gallonsPumped > 0 { parts.append("\(short(e.gallonsPumped)) gal removed") }
                if e.cost > 0 { parts.append(currency(e.cost)) }
                if !parts.isEmpty {
                    line(parts.joined(separator: "  ·  "), size: 9, colour: .secondaryLabel,
                         indent: 12, gapAfter: 1)
                }
                if !e.findings.isEmpty { line(e.findings, size: 9, indent: 12, gapAfter: 1) }
                if !e.notes.isEmpty { line(e.notes, size: 9, colour: .secondaryLabel, indent: 12, gapAfter: 1) }
                y += 3
            }

            rule()
            line("Dates and figures above are as entered by the property owner from their own "
                 + "receipts and reports. \(AppConfig.appName) keeps the record; it does not "
                 + "inspect the system, certify it, or set any county's requirements.",
                 size: 9, colour: .secondaryLabel)
        }
        return url
    }

    private static func short(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    private static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}
