import SwiftUI
import SwiftData

/// Measuring what is in the tank.
///
/// Optional, and deliberately so: most owners never open the tank, and the interval alone
/// is a reasonable way to run a septic system. But when the lid is off — usually because a
/// pumper is standing there — these are the figures that decide whether it needs pumping
/// now, and they can contradict the calendar in both directions.
struct TankCheckView: View {
    let system: SepticSystem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allSystems: [SepticSystem]

    @State private var date = Date()
    @State private var checkedBy = ""
    @State private var scum: Double = 0
    @State private var sludge: Double = 0
    @State private var liquidDepth: Double = 0
    @State private var scumClearance: Double = 0
    @State private var sludgeClearance: Double = 0
    @State private var notes = ""

    private var draft: TankCheck {
        let check = TankCheck(date: date)
        check.scumInches = scum; check.sludgeInches = sludge
        check.liquidDepthInches = liquidDepth
        check.scumClearanceInches = scumClearance
        check.sludgeClearanceInches = sludgeClearance
        return check
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Measured by", text: $checkedBy)
                }

                Section {
                    Inches("Scum layer", value: $scum)
                    Inches("Sludge layer", value: $sludge)
                    Inches("Liquid depth of the tank", value: $liquidDepth)
                } header: {
                    Text("Layers")
                } footer: {
                    Text("Scum floats, sludge settles. Without the tank's liquid depth there is no fraction to work out, so that line is left out of the verdict rather than guessed at.")
                }

                Section {
                    Inches("Scum above the baffle", value: $scumClearance)
                    Inches("Sludge below the baffle", value: $sludgeClearance)
                } header: {
                    Text("Clearance to the outlet baffle")
                } footer: {
                    Text("The figures an inspector writes down. Published guidance is to pump once the bottom of the scum is within 3 inches of the bottom of the outlet baffle, or the top of the sludge within 12 inches of it.")
                }

                let verdict = draft.verdict
                if verdict.measured {
                    Section("What that means") {
                        Label(verdict.pumpIndicated ? "Pumping is indicated" : "Within the published limits",
                              systemImage: verdict.pumpIndicated ? "exclamationmark.octagon.fill" : "checkmark.circle.fill")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(verdict.pumpIndicated ? .red : .green)
                        ForEach(verdict.reasons, id: \.self) { reason in
                            Text(reason).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Baffles, roots, anything unusual", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if !system.sortedChecks.isEmpty {
                    Section("Earlier measurements") {
                        ForEach(system.sortedChecks.prefix(10)) { check in
                            HStack {
                                Text(check.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                Spacer()
                                if let fraction = check.solidsFraction {
                                    Text("\(Int((fraction * 100).rounded()))% solids")
                                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                }
                                if check.verdict.pumpIndicated {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2).foregroundStyle(.red)
                                }
                            }
                        }
                        .onDelete(perform: deleteChecks)
                    }
                }
            }
            .navigationTitle("Measure the tank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!draft.verdict.measured) }
            }
        }
    }

    private func deleteChecks(_ offsets: IndexSet) {
        let list = Array(system.sortedChecks.prefix(10))
        for index in offsets { context.delete(list[index]) }
        try? context.save()
    }

    private func save() {
        let check = draft
        check.checkedBy = checkedBy
        check.notes = notes
        check.system = system
        context.insert(check)
        try? context.save()
        WidgetSync.update(with: allSystems)
        dismiss()
    }
}

private struct Inches: View {
    let title: String
    @Binding var value: Double

    init(_ title: String, value: Binding<Double>) {
        self.title = title
        self._value = value
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 4) {
                TextField("—", value: $value, format: .number)
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                Text("in").foregroundStyle(.secondary)
            }
        }
    }
}
