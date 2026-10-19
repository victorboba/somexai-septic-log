import Foundation

/// One row per event, across every property. The spreadsheet a homeowner hands to an
/// accountant or a new pumping company.
enum CSVExporter {
    static func export(_ systems: [SepticSystem]) throws -> URL {
        var rows = ["property,address,system_type,tank_gallons,date,event,company,license,technician,gallons_pumped,cost,findings,notes"]
        for system in systems.sorted(by: { $0.headline < $1.headline }) {
            for e in system.sortedEvents {
                rows.append([
                    system.headline, system.address, system.systemType.name,
                    num(system.tankGallons),
                    ISO8601DateFormatter.day.string(from: e.date), e.kind.name,
                    e.company, e.licenseNumber, e.technician,
                    num(e.gallonsPumped), num(e.cost),
                    e.findings, e.notes,
                ].map(escape).joined(separator: ","))
            }
        }
        let text = rows.joined(separator: "\n") + "\n"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppConfig.exportFileStem)-\(ISO8601DateFormatter.day.string(from: .now)).csv")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Zero means "not recorded", so it is left blank rather than printed as a measured 0.
    private static func num(_ value: Double) -> String {
        value == 0 ? "" : (value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value))
    }

    private static func escape(_ value: String) -> String {
        value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" })
            ? "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
            : value
    }
}

extension ISO8601DateFormatter {
    static let day: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
