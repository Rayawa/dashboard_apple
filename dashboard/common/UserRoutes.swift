import Foundation

enum AppRoute: Hashable {
    case appDetail(AppDetailTarget)
    case search
    case submitApp
    case tutorial
    case developer
    case friends
    case web(WebPagePayload)
    case contact
    case appLog
    case htmlPage(HTMLPagePayload)
}

extension AppRoute: Identifiable {
    var id: String {
        switch self {
        case .appDetail(let target):
            "appDetail:\(target.appId ?? target.packageName ?? "unknown")"
        case .search:
            "search"
        case .submitApp:
            "submitApp"
        case .tutorial:
            "tutorial"
        case .developer:
            "developer"
        case .friends:
            "friends"
        case .web(let payload):
            "web:\(payload.title):\(payload.url.absoluteString)"
        case .contact:
            "contact"
        case .appLog:
            "appLog"
        case .htmlPage(let payload):
            "htmlPage:\(payload.title):\(payload.resourceName)"
        }
    }
}
