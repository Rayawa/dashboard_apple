import Foundation

enum ProfileStorage {
    static func getUsername() -> String {
        UserDefaults.standard.string(forKey: DashboardSettings.userName) ?? ""
    }

    static func setUsername(_ value: String?) {
        UserDefaults.standard.set(value, forKey: DashboardSettings.userName)
    }
}
