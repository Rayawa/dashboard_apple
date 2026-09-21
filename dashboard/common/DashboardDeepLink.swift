import Foundation

nonisolated enum DashboardDeepLink {
    static func appTarget(from url: URL) -> AppDetailTarget? {
        guard url.scheme?.lowercased() == "hmdashboard" || url.scheme?.lowercased() == "https" else {
            return nil
        }
        return DashboardInputParser.target(from: url)
    }
}
