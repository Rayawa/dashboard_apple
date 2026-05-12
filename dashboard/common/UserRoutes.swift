enum AppRoute: Hashable {
    case friends
    case friendWeb(WebPagePayload)
    case contact
    case about
    case aboutWeb(WebPagePayload)
    case queryWeb(WebPagePayload)
    case appLog
    case htmlPage(HTMLPagePayload)
}

extension AppRoute: Identifiable {
    var id: String {
        switch self {
        case .friends:
            "friends"
        case .friendWeb(let payload):
            "friendWeb:\(payload.title):\(payload.urlString)"
        case .contact:
            "contact"
        case .about:
            "about"
        case .aboutWeb(let payload):
            "aboutWeb:\(payload.title):\(payload.urlString)"
        case .queryWeb(let payload):
            "queryWeb:\(payload.title):\(payload.urlString)"
        case .appLog:
            "appLog"
        case .htmlPage(let payload):
            "htmlPage:\(payload.title):\(payload.resourceName)"
        }
    }
}
