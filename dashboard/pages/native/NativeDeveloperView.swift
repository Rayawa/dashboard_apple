import SwiftUI
#if os(iOS)
import UIKit
#endif

struct NativeDeveloperView: View {
    private var fields: [(String, String)] {
        [
            ("应用版本", DashboardMeta.appVersion),
            ("内部构建号", DashboardMeta.buildNumber),
            ("Bundle Identifier", DashboardMeta.appBundleName),
            ("Custom User-Agent", UAProvider.customUserAgent),
            ("平台", platformName),
            ("系统版本", ProcessInfo.processInfo.operatingSystemVersionString),
            ("语言环境", Locale.current.identifier),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("仅用于诊断平台适配、网络请求标识与版本信息；不展示精确硬件型号。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                DashboardCard {
                    ForEach(Array(fields.enumerated()), id: \.element.0) { index, field in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(field.0).font(.caption).foregroundStyle(.secondary)
                            Text(field.1.isEmpty ? "-" : field.1)
                                .font(.callout)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 7)
                        .accessibilityElement(children: .combine)
                        if index < fields.count - 1 { Divider() }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .navigationTitle("开发者信息")
    }

    private var platformName: String {
#if os(macOS)
        "macOS"
#else
        UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
#endif
    }
}
