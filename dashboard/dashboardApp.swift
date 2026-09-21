import SwiftUI

@main
struct dashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
#if os(macOS)
                .frame(minWidth: 760, minHeight: 600)
#endif
        }
#if os(macOS)
        .defaultSize(width: 1180, height: 800)
#endif
    }
}
