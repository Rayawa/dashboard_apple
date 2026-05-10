import SwiftUI

struct FriendPageView: View {
    let onNavigate: (AppRoute) -> Void
    @Environment(\.openURL) private var openURL

    private let friendSites: [FriendSite] = [
        .init(id: "hap", title: "Hap资源站", url: DashboardURLs.hapStore, icon: "shippingbox"),
        .init(id: "next", title: "NEXT Store", url: DashboardURLs.nextStore, icon: "bag"),
        .init(id: "open", title: "Open Store", url: DashboardURLs.openStore, icon: "shippingbox.circle"),
        .init(id: "dz", title: "应用荟萃", url: DashboardURLs.dzTap, icon: "square.stack.3d.up"),
    ]

    private let friendApps: [FriendApp] = [
        .init(id: "subscribe", title: "记得订阅", appId: "C6917594526782928388", icon: "bell.badge")
    ]

    private let otherSites: [FriendSite] = [
        .init(id: "ag", title: "AppGallery统计数据", url: DashboardURLs.agStatistics, icon: "chart.bar")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("重要提示：您正在访问友情链接")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Text("友情链接内网站展示的任何内容均与Hm应用看板无关；Harmony Gallery项目组不负责维护友情链接内容。")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                group("使用Harmony Gallery数据的站点") {
                    ForEach(friendSites) { site in
                        Button {
                            onNavigate(.friendWeb(.init(title: site.title, urlString: site.url.absoluteString)))
                        } label: {
                            row(site.title, icon: site.icon)
                        }
                        .buttonStyle(.plain)
                    }
                }

                group("使用Harmony Gallery数据的应用") {
                    ForEach(friendApps) { app in
                        Button {
                            openURL(DashboardURLs.appGalleryDetail(appId: app.appId))
                        } label: {
                            row(app.title, icon: app.icon)
                        }
                        .buttonStyle(.plain)
                    }
                }

                group("其他站点") {
                    ForEach(otherSites) { site in
                        Button {
                            onNavigate(.friendWeb(.init(title: site.title, urlString: site.url.absoluteString)))
                        } label: {
                            row(site.title, icon: site.icon)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("友情链接")
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            VStack(spacing: 0) { content() }
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }

    private func row(_ title: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
