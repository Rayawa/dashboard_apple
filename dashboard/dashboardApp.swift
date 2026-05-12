import SwiftUI

@main
struct dashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
#if os(macOS)
                .frame(minWidth: 1100, minHeight: 760)
#endif
        }
#if os(macOS)
        .defaultSize(width: 1360, height: 860)
#endif
    }
}
