import Foundation

struct DashboardPalette {
    let top = ColorToken(red: 0.94, green: 0.97, blue: 1.0)
    let middle = ColorToken(red: 0.84, green: 0.92, blue: 0.99)
    let bottom = ColorToken(red: 0.95, green: 0.94, blue: 0.98)
    let cyan = ColorToken(red: 0.12, green: 0.74, blue: 0.86)
    let blue = ColorToken(red: 0.15, green: 0.42, blue: 0.96)
    let coral = ColorToken(red: 0.99, green: 0.49, blue: 0.59)
}

struct ColorToken {
    let red: Double
    let green: Double
    let blue: Double
}

struct FormData {
    var appName = ""
    var appLink = ""
    var packageName = ""
    var appId = ""
    var remark = ""

    mutating func clear(includeName: Bool) {
        if includeName { appName = "" }
        appLink = ""
        packageName = ""
        appId = ""
        remark = ""
    }
}

struct ExtractedSeed {
    var appName: String?
    var appLink: String?
    var packageName: String?
    var appId: String?
    var date: String?
}

struct FriendSite: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL
    let icon: String
}

struct FriendApp: Identifiable, Hashable {
    let id: String
    let title: String
    let appId: String
    let icon: String
}

struct UpdateLog: Identifiable, Hashable {
    let version: String
    let date: String
    let type: ReleaseType
    let items: [String]

    var id: String { version }
}

enum ReleaseType: String, CaseIterable, Hashable {
    case beta
    case rc
    case release

    var title: String {
        switch self {
        case .beta: "Beta"
        case .rc: "RC"
        case .release: "Release"
        }
    }
}

struct WebPagePayload: Hashable {
    let title: String
    let urlString: String
}

struct HTMLPagePayload: Hashable {
    let title: String
    let resourceName: String
}
