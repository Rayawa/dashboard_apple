import Foundation

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
