import Foundation
import Darwin
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum SiteEndpoint: String, CaseIterable, Identifiable {
    case s
    case t

    var id: String { rawValue }

    var title: String {
        switch self {
        case .s: "S站"
        case .t: "T站"
        }
    }

    var shortTitle: String {
        switch self {
        case .s: "S"
        case .t: "T"
        }
    }

    var subtitle: String {
        switch self {
        case .s: "数据库与服务"
        case .t: "应用详情与落地页"
        }
    }

    var icon: String {
        switch self {
        case .s: "server.rack"
        case .t: "safari"
        }
    }

    var url: URL {
        switch self {
        case .s: return DashboardURLs.sBase
        case .t: return DashboardURLs.tBase
        }
    }

    static func fromPersisted(_ value: String) -> SiteEndpoint {
        SiteEndpoint.allCases.first { $0.url.absoluteString == value } ?? .s
    }
}

enum ShellSection: String, CaseIterable, Identifiable {
    case browser
    case user

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browser: "浏览"
        case .user: "我的"
        }
    }

    var subtitle: String {
        switch self {
        case .browser: "站点切换与网页操作"
        case .user: "设置、投稿、查询与更多"
        }
    }

    var icon: String {
        switch self {
        case .browser: "globe.asia.australia"
        case .user: "person.crop.circle"
        }
    }
}

enum DashboardSettings {
    static let vibration = "vibrationON"
    static let holdCheck = "holdCheckON"
    static let buttonRight = "buttonPositionRIGHT"
    static let tabBarAuto = "tabBarAutoON"
    static let immersiveTexture = "immersiveTextureON"
    static let userName = "userName"
    static let pageURL = "pageUrl"
}

enum DashboardURLs {
    static let mainPage = URL(string: "https://dashboard.rayawa.top")!
    static let sBase = URL(string: "https://ddns.shenjack.top:10003/")!
    static let tBase = URL(string: "https://hmos.txit.top/")!
    static let eguiBase = URL(string: "https://ddns.shenjack.top:10003/egui/")!
    static let sAPIBase = sBase.appending(path: "api/v0/")

    static let hapStore = URL(string: "https://hdc.osbdf.com/")!
    static let agStatistics = URL(string: "https://appgallery.info/index.html")!
    static let dzTap = URL(string: "https://dztap.com/app.html")!
    static let openStore = URL(string: "https://next.betahub.tech/")!
    static let nextStore = URL(string: "https://next.vcck.cn/#/")!
    static let appGalleryDetailBase = URL(string: "https://appgallery.huawei.com/app/detail")!
    static let sponsor = URL(string: "https://afdian.com/a/shenjack")!
    static let miit = URL(string: "https://beian.miit.gov.cn/#/Integrated/index")!

    static func appGalleryDetail(appId: String) -> URL {
        var components = URLComponents(url: appGalleryDetailBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: appId)]
        return components?.url ?? appGalleryDetailBase
    }
}

enum DashboardMeta {
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.3"
    static let appBundleName = Bundle.main.bundleIdentifier ?? "top.rayawa.dashboard"
}

struct UAProvider {
    static var customUserAgent: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "top.rayawa.dashboard.apple?"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0?"

        #if os(iOS)
        let osName = UIDevice.current.systemName + UIDevice.current.systemVersion
        let deviceCategory = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
        #elseif os(macOS)
        let osName = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceCategory = "pc"
        #endif

        #if os(iOS)
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)

        var modelBuffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &modelBuffer, &size, nil, 0)

        let modelCode = String(cString: modelBuffer)
        #elseif os(macOS)
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        var modelBuffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &modelBuffer, &size, nil, 0)

        let modelCode = String(cString: modelBuffer)
        #endif

        return "\(bundleID)(\(appVersion)) | \(deviceCategory)/\(modelCode)/\(osName)"
    }
}
