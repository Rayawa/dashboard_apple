enum AppRoute: Hashable {
    case user
    case submit
    case query(String?)
    case friends
    case friendWeb(WebPagePayload)
    case contact
    case about
    case aboutWeb(WebPagePayload)
    case queryWeb(WebPagePayload)
    case appLog
    case htmlPage(HTMLPagePayload)
}
