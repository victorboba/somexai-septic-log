import SwiftUI
import SwiftData

/// What is in the ground, and how often it needs attention.
///
/// Most of this is filled in once, from a permit, an old receipt or a guess, and then left
/// alone for a decade. So every field tolerates being blank: an unknown tank size is not an
/// error, and an interval left off means the property does not have that duty at all.
struct SystemEditorView: View {
    @Bindable var system: SepticSystem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query private var allSystems: [SepticSystem]

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Name it (Home, Cabin, 14 Mill Road)", text: $system.propertyName)
                    TextField("Address", text: $system.address, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    Picker("System type", selection: Binding(
                        get: { system.systemType },
                        set: { newValue in
                            system.systemType = newValue
                            // An aerobic unit almost always comes with a service contract,
                            // so offer the clock rather than making them find it.
                            if newValue.usuallyHasServiceContract, system.atuServiceIntervalMonths == 0 {
                                system.atuServiceIntervalMonths = 6
                            }
                        })) {
                        ForEach(SystemType.allCases) { Text($0.name).tag($0) }
                    }
                    Picker("Tank material", selection: $system.tankMaterial) {
                        ForEach(TankMaterial.allCases) { Text($0.name).tag($0) }
                    }
                    LabeledContent("Tank size") {
                        HStack(spacing: 4) {
                            TextField("unknown", value: $system.tankGallons, format: .number)
                                .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            Text("gal").foregroundStyle(.secondary)
                        }
                    }
                    Stepper("Compartments: \(system.compartments)", value: $system.compartments, in: 1...4)
                    Stepper(system.householdSize == 0 ? "Household: not set" : "Household: \(system.householdSize) people",
                            value: $system.householdSize, in: 0...12)
                } header: {
                    Text("The system")
                } footer: {
                    if let note = system.tankMaterial.note {
                        Text(note)
                    } else {
                        Text("If you do not know, leave it. The next pumper can tell you, and you can fill it in then.")
                    }
                }

                Section("Paperwork") {
                    DatePicker("Installed", selection: Binding(
                        get: { system.installedOn ?? Date() },
                        set: { system.installedOn = $0 }),
                        displayedComponents: .date)
                    .opacity(system.installedOn == nil ? 0.5 : 1)
                    if system.installedOn == nil {
                        Button("Set the install date") { system.installedOn = Date() }
                            .font(.caption)
                    }
                    TextField("Permit number", text: $system.permitNumber)
                    TextField("Health department or county", text: $system.healthDepartment)
                }

                Section {
                    TextField("Where the lids are", text: $system.accessNotes, axis: .vertical)
                        .lineLimit(2...5)
                    PhotoField(data: $system.accessPhoto, label: "Photo of the lid location")
                } header: {
                    Text("Finding it again")
                } footer: {
                    Text("Pace it off something that will still be there: a fence post, a corner of the house. Every pumping company asks, and digging for a lid is billed by the hour.")
                }

                Section {
                    Stepper(system.pumpIntervalYears == 0 ? "Pumping: not tracked" : "Pumping: every \(system.pumpIntervalYears) years",
                            value: $system.pumpIntervalYears, in: 0...15)
                    Interval("Effluent filter", months: $system.filterIntervalMonths, suggestion: 12)
                    Interval("Aerobic unit service", months: $system.atuServiceIntervalMonths, suggestion: 6)
                    Interval("Inspection", months: $system.inspectionIntervalMonths, suggestion: 36)
                } header: {
                    Text("How often")
                } footer: {
                    Text(Duty.pumpOut.why)
                }

                Section("Notes") {
                    TextField("Anything worth remembering", text: $system.notes, axis: .vertical)
                        .lineLimit(2...6)
                }

                if allSystems.count > 1 {
                    Section {
                        Button("Delete this property", role: .destructive) {
                            context.delete(system)
                            try? context.save()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("System details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        WidgetSync.update(with: allSystems)
                        dismiss()
                    }
                }
            }
        }
    }
}

/// An interval in months, with "off" as a first-class option rather than a zero to type.
private struct Interval: View {
    let title: String
    @Binding var months: Int
    let suggestion: Int

    init(_ title: String, months: Binding<Int>, suggestion: Int) {
        self.title = title
        self._months = months
        self.suggestion = suggestion
    }

    var body: some View {
        Picker(title, selection: $months) {
            Text("Not tracked").tag(0)
            Text("Every 3 months").tag(3)
            Text("Every 6 months").tag(6)
            Text("Every year").tag(12)
            Text("Every 2 years").tag(24)
            Text("Every 3 years").tag(36)
            Text("Every 5 years").tag(60)
        }
    }
}
