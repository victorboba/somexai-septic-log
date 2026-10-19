import SwiftUI
import SwiftData

@main
struct SepticLog: App {
    @State private var entitlements = EntitlementStore()
    private let container: ModelContainer

    init() {
        let schema = Schema([SepticSystem.self, ServiceEvent.self, TankCheck.self])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: AppConfig.iCloudSyncEnabled ? .automatic : .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetData") {
            try? container.mainContext.delete(model: TankCheck.self)
            try? container.mainContext.delete(model: ServiceEvent.self)
            try? container.mainContext.delete(model: SepticSystem.self)
            try? container.mainContext.save()
        }
        if ProcessInfo.processInfo.arguments.contains("-sampleData"),
           (try? container.mainContext.fetchCount(FetchDescriptor<SepticSystem>())) == 0 {
            SampleData.insert(into: container.mainContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlements)
        }
        .modelContainer(container)
    }
}
