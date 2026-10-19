import SwiftUI
import SwiftData

/// One property, one timeline.
///
/// A homeowner has one septic system and thinks about it roughly twice a decade, so the
/// screen is not a list of records to browse — it is a standing answer to "is anything
/// coming due", with the history underneath it in the order it happened. Someone with a
/// rental or a cabin gets a property menu in the title bar; everyone else never sees it.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SepticSystem.createdAt) private var systems: [SepticSystem]

    @State private var selectedID: UUID?
    @State private var editingSystem: SepticSystem?
    @State private var editingEvent: ServiceEvent?
    @State private var addingEvent = false
    @State private var measuring = false
    @State private var showingSettings = false
    @State private var exportFile: ExportFile?
    @State private var exportError: String?

    private var system: SepticSystem? {
        systems.first { $0.id == selectedID } ?? systems.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let system {
                    timeline(for: system)
                } else {
                    ContentUnavailableView {
                        Label("No system set up yet", systemImage: "house.and.flag")
                    } description: {
                        Text("Start with what you know about the system in your yard. You can fill in the rest after the next visit.")
                    } actions: {
                        Button("Set up my system") { addSystem() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(system?.headline ?? AppConfig.appName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(item: $editingSystem) { SystemEditorView(system: $0) }
            .sheet(item: $editingEvent) { event in
                EventEditorView(system: event.system ?? system!, event: event)
            }
            .sheet(isPresented: $addingEvent) {
                if let system { EventEditorView(system: system, event: nil) }
            }
            .sheet(isPresented: $measuring) {
                if let system { TankCheckView(system: system) }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(item: $exportFile) { ShareSheet(url: $0.url) }
            .alert("Export failed", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: { Text(exportError ?? "") }
            .onAppear(perform: openNewEventIfRequestedByShortcut)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink { HowToView() } label: {
                Label("How do I use this app?", systemImage: "questionmark.circle")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let system {
                    Button { addingEvent = true } label: { Label("Record service", systemImage: "plus") }
                    Button { editingSystem = system } label: { Label("System details", systemImage: "house.and.flag") }
                    Button { measuring = true } label: { Label("Measure the tank", systemImage: "ruler") }
                    Divider()
                    Button { export(.pdf, system) } label: { Label("System record (PDF)", systemImage: "doc.richtext") }
                    Button { export(.csv, system) } label: { Label("Every record (CSV)", systemImage: "tablecells") }
                    Divider()
                }
                if systems.count > 1 {
                    Picker("Property", selection: Binding(
                        get: { system?.id ?? UUID() },
                        set: { selectedID = $0 })) {
                        ForEach(systems) { Text($0.headline).tag($0.id) }
                    }
                    Divider()
                }
                Button { addSystem() } label: { Label("Add another property", systemImage: "plus.square.on.square") }
                Button { showingSettings = true } label: { Label("Settings", systemImage: "gear") }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }

    // MARK: - The timeline

    private func timeline(for system: SepticSystem) -> some View {
        List {
            Section { DueCard(system: system) }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))

            if system.sortedEvents.isEmpty {
                Section {
                    Button { addingEvent = true } label: {
                        Label("Record the last pumping", systemImage: "plus.circle.fill")
                    }
                } footer: {
                    Text("Even an approximate date starts the clock. If the receipt is in a drawer somewhere, photograph it when you find it.")
                }
            }

            ForEach(years(of: system), id: \.year) { group in
                Section(String(group.year)) {
                    ForEach(group.events) { event in
                        Button { editingEvent = event } label: { EventRow(event: event) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { offsets in delete(offsets, in: group.events) }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func years(of system: SepticSystem) -> [(year: Int, events: [ServiceEvent])] {
        let groups = Dictionary(grouping: system.sortedEvents) {
            Calendar.current.component(.year, from: $0.date)
        }
        return groups.keys.sorted(by: >).map { (year: $0, events: groups[$0] ?? []) }
    }

    // MARK: - Actions

    private func addSystem() {
        let system = SepticSystem()
        context.insert(system)
        try? context.save()
        selectedID = system.id
        editingSystem = system
    }

    private func delete(_ offsets: IndexSet, in events: [ServiceEvent]) {
        for index in offsets { context.delete(events[index]) }
        try? context.save()
        WidgetSync.update(with: systems)
    }

    private enum ExportKind { case pdf, csv }

    private func export(_ kind: ExportKind, _ system: SepticSystem) {
        do {
            let url = kind == .pdf
                ? try PDFExporter.export(system)
                : try CSVExporter.export(systems)
            exportFile = ExportFile(url: url)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func openNewEventIfRequestedByShortcut() {
        let defaults = WidgetSnapshot.defaults
        guard defaults.bool(forKey: LogEntryIntent.pendingKey) else { return }
        defaults.removeObject(forKey: LogEntryIntent.pendingKey)
        if systems.isEmpty { addSystem() } else { addingEvent = true }
    }
}

/// The standing answer. Every duty the property actually has, worst first.
private struct DueCard: View {
    let system: SepticSystem

    private var duties: [(duty: Duty, status: DutyStatus)] { system.duties() }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if duties.isEmpty {
                Label("No intervals set", systemImage: "calendar.badge.exclamationmark")
                    .font(.subheadline.weight(.semibold))
                Text("Open System details and set how often this property is pumped. Nothing is tracked until you do.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(duties, id: \.duty) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: item.duty.symbol)
                            .foregroundStyle(tint(item.status))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.duty.name).font(.subheadline.weight(.medium))
                            Text(item.status.headline)
                                .font(.caption)
                                .foregroundStyle(item.status.needsAttention ? tint(item.status) : .secondary)
                        }
                        Spacer()
                        if let due = system.nextDue(item.duty) {
                            Text(due.formatted(.dateTime.month(.abbreviated).year()))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // The tank can disagree with the calendar, and when it does it wins.
            if let check = system.sortedChecks.first, check.verdict.measured {
                Divider()
                let verdict = check.verdict
                Label(verdict.pumpIndicated ? "The tank says pump it" : "Measured within the limits",
                      systemImage: verdict.pumpIndicated ? "exclamationmark.octagon.fill" : "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(verdict.pumpIndicated ? .red : .green)
                ForEach(verdict.reasons, id: \.self) { reason in
                    Text(reason).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func tint(_ status: DutyStatus) -> Color {
        switch status {
        case .overdue: .red
        case .dueSoon: .orange
        case .noRecord: .secondary
        default: .green
        }
    }
}

private struct EventRow: View {
    let event: ServiceEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.kind.symbol)
                .font(.callout)
                .foregroundStyle(event.kind == .alarm ? .red : .secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.kind.name).font(.subheadline.weight(.medium))
                Text(event.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
                if !event.company.isEmpty {
                    Text(event.company).font(.caption).foregroundStyle(.secondary)
                }
                if !event.findings.isEmpty {
                    Text(event.findings).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if event.gallonsPumped > 0 {
                    Text("\(Int(event.gallonsPumped)) gal")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                if event.documentPhoto != nil {
                    Image(systemName: "paperclip").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
