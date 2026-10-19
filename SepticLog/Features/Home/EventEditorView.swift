import SwiftUI
import SwiftData

/// One thing that happened to the system.
///
/// Everything is optional except the date and what it was, because a homeowner filling in
/// five years of history from memory will not have the licence numbers — and a record with
/// gaps in it is still the record they did not have before.
struct EventEditorView: View {
    let system: SepticSystem
    var event: ServiceEvent?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview
    @Query private var allSystems: [SepticSystem]

    @State private var date = Date()
    @State private var kind: ServiceKind = .pumpOut
    @State private var company = ""
    @State private var licenseNumber = ""
    @State private var technician = ""
    @State private var gallons: Double = 0
    @State private var cost: Double = 0
    @State private var findings = ""
    @State private var notes = ""
    @State private var photo: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("What happened", selection: $kind) {
                        ForEach(ServiceKind.allCases) { kind in
                            Label(kind.name, systemImage: kind.symbol).tag(kind)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } footer: {
                    if !kind.hint.isEmpty { Text(kind.hint) }
                }

                if kind.countsAsWork {
                    Section("Who did it") {
                        TextField("Company", text: $company)
                        TextField("Licence number", text: $licenseNumber)
                        TextField("Technician", text: $technician)
                    }
                }

                if kind == .pumpOut {
                    Section("Pumping") {
                        LabeledContent("Gallons removed") {
                            TextField("—", value: $gallons, format: .number)
                                .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        }
                    }
                }

                Section(kind == .drainfield || kind == .alarm ? "What you saw" : "What they found") {
                    TextField(kind == .drainfield
                              ? "Wet ground, odour, slow drains…"
                              : "Baffles, filter, pump, drainfield…",
                              text: $findings, axis: .vertical)
                        .lineLimit(2...6)
                }

                if kind.countsAsWork {
                    Section("Cost") {
                        LabeledContent("Paid") {
                            TextField("—", value: $cost, format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                }

                Section {
                    PhotoField(data: $photo, label: "Photo of the receipt or report")
                } header: {
                    Text("Paperwork")
                } footer: {
                    Text("Photograph the receipt or the county's form. At a sale this is the page somebody asks for, and paper in a drawer fades.")
                }

                Section("Notes") {
                    TextField("Anything else", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle(event == nil ? "Record service" : "Edit record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let e = event else { return }
        date = e.date; kind = e.kind; company = e.company
        licenseNumber = e.licenseNumber; technician = e.technician
        gallons = e.gallonsPumped; cost = e.cost
        findings = e.findings; notes = e.notes; photo = e.documentPhoto
    }

    private func save() {
        let record = event ?? ServiceEvent()
        record.date = date; record.kind = kind
        record.company = company; record.licenseNumber = licenseNumber
        record.technician = technician
        record.gallonsPumped = gallons; record.cost = cost
        record.findings = findings; record.notes = notes
        record.documentPhoto = photo
        if event == nil {
            record.system = system
            context.insert(record)
        }
        try? context.save()
        WidgetSync.update(with: allSystems)
        // The record is the product, so saving one is the success moment.
        ReviewPrompter.recordSuccess(request: requestReview)
        dismiss()
    }
}
