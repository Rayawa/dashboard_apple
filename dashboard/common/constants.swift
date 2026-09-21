import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum DashboardURLs {
    static let mainPage = URL(string: "https://dashboard.rayawa.top")!
    static let sBase = URL(string: "https://ddns.shenjack.top:10003/")!
    static let sPublicBase = URL(string: "https://shenjack.top:10003/")!
    static let tBase = URL(string: "https://hmos.txit.top/")!
    static let eguiBase = URL(string: "https://shenjack.top:10003/egui/")!
    static let tDashboard = tBase.appending(path: "dashboard")
    static let sAPIBase = sBase.appending(path: "api/v0/")
    static let apiDocs = sBase.appending(path: "docs")
    static let webChangeLog = tBase.appending(path: "changelog")

    static let hapStore = URL(string: "https://sydxky.cn/")!
    static let agStatistics = URL(string: "https://appgallery.info/index.html")!
    static let dzTap = URL(string: "https://home.dztap.com/index")!
    static let openStore = URL(string: "https://next.betahub.tech/")!
    static let nextStore = URL(string: "https://next.vcck.cn/#/")!
    static let fangzhou = URL(string: "https://fangzhou.club/")!
    static let appGalleryDetailBase = URL(string: "https://appgallery.huawei.com/app/detail")!
    static let sponsor = URL(string: "https://afdian.com/a/shenjack")!
    static let meowChannel = URL(string: "https://www.chuckfang.com/MeoW/appLinking?channelId=8bbba7f53bf9458284a41d04f295450b")!
    static let miit = URL(string: "https://beian.miit.gov.cn/#/Integrated/index")!

    static func appGalleryDetail(appId: String) -> URL {
        var components = URLComponents(url: appGalleryDetailBase, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: appId)]
        return components?.url ?? appGalleryDetailBase
    }

    static func sAppDetail(appId: String) -> URL {
        var components = URLComponents(url: sPublicBase.appending(path: "dashboard"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "app_id", value: appId)]
        return components?.url ?? sPublicBase
    }

    static func appDetailShareURL(appId: String, useTSite: Bool) -> URL {
        useTSite ? tBase.appending(path: "app/\(appId)") : sAppDetail(appId: appId)
    }
}

enum DashboardMeta {
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "30100001"
    static let appBundleName = Bundle.main.bundleIdentifier ?? "top.rayawa.dashboard.apple"
}

struct UAProvider {
    static var customUserAgent: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "top.rayawa.dashboard.apple?"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0?"

        #if os(iOS)
        let osName = UIDevice.current.systemName
        let deviceCategory = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
        #elseif os(macOS)
        let osName = "macOS"
        let deviceCategory = "pc"
        #endif

        return "\(bundleID)/\(appVersion) (\(deviceCategory); \(osName))"
    }
}

enum DashboardFeedback {
    static func selection(level: Int? = nil) {
        let savedLevel = (UserDefaults.standard.object(forKey: "haptic_level") as? NSNumber)?.intValue ?? 1
        let configuredLevel = level ?? savedLevel
        guard configuredLevel > 0 else { return }
#if os(iOS)
        let style: UIImpactFeedbackGenerator.FeedbackStyle = configuredLevel > 1 ? .medium : .light
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
#elseif os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(
            configuredLevel > 1 ? .generic : .alignment,
            performanceTime: .now
        )
#endif
    }
}

let dashboardPageBackground: Color = {
#if os(iOS)
    Color(uiColor: .systemGroupedBackground)
#elseif os(macOS)
    Color(nsColor: .windowBackgroundColor)
#endif
}()

enum DashboardModalSize {
    case warning
    case standard
    case tutorial
    case web

    var minWidth: CGFloat {
        switch self {
        case .warning: 540
        case .standard: 700
        case .tutorial: 880
        case .web: 960
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .warning: 420
        case .standard: 560
        case .tutorial: 680
        case .web: 720
        }
    }
}

private struct DashboardVisibilityKey: EnvironmentKey {
    static let defaultValue = DashboardVisibilityConfig.restricted
}

extension EnvironmentValues {
    var dashboardVisibility: DashboardVisibilityConfig {
        get { self[DashboardVisibilityKey.self] }
        set { self[DashboardVisibilityKey.self] = newValue }
    }
}

struct DashboardModalCloseToolbarModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
    }
}

extension View {
    func dashboardModalCloseToolbar() -> some View {
        modifier(DashboardModalCloseToolbarModifier())
    }

    func dashboardModalFrame(_ size: DashboardModalSize) -> some View {
        modifier(DashboardModalFrameModifier(size: size))
    }
}

private struct DashboardModalFrameModifier: ViewModifier {
    let size: DashboardModalSize

    func body(content: Content) -> some View {
#if os(macOS)
        content
            .frame(
                minWidth: size.minWidth,
                idealWidth: size.minWidth,
                minHeight: size.minHeight,
                idealHeight: size.minHeight,
                alignment: .topLeading
            )
#else
        content
#endif
    }
}
