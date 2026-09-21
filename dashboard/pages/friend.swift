import SwiftUI

struct FriendPageView: View {
    let onOpenModal: (AppRoute) -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.dashboardVisibility) private var visibility

    private let friendSites: [FriendLink] = [
        .init(id: "hap", title: "Hap资源站", url: DashboardURLs.hapStore, icon: "shippingbox"),
        .init(id: "dz", title: "应用荟萃", url: DashboardURLs.dzTap, icon: "square.stack.3d.up"),
        .init(id: "open", title: "Open Store", url: DashboardURLs.openStore, icon: "shippingbox.circle"),
        .init(id: "next", title: "NEXT Store", url: DashboardURLs.nextStore, icon: "bag"),
        .init(id: "fangzhou", title: "方舟网", url: DashboardURLs.fangzhou, icon: "ferry"),
    ]

    private let friendApps: [FriendLink] = [
        .init(id: "getrace", title: "迹得", packageName: "cn.biandangroup.getrace", icon: "figure.run"),
        .init(id: "subscribe", title: "记得订阅", packageName: "com.xxtstudio.accountDL", icon: "bell.badge"),
        .init(id: "subscribe-atomic", title: "记得订阅（元服务）", packageName: "com.atomicservice.6917600885144283966", icon: "bell.and.waves.left.and.right"),
        .init(id: "paper-talk", title: "纸语", packageName: "com.my.papertalk", icon: "text.book.closed"),
    ]

    private let otherSites: [FriendLink] = [
        .init(id: "ag", title: "AppGallery统计数据", url: DashboardURLs.agStatistics, icon: "chart.bar")
    ]

    private var projectSites: [FriendLink] {
        var links = [
            FriendLink(id: "project", title: "项目网站首页", url: DashboardURLs.mainPage, icon: "house"),
            FriendLink(id: "s", title: "S站", url: DashboardURLs.sBase, icon: "server.rack"),
            FriendLink(id: "egui", title: "Egui", url: DashboardURLs.eguiBase, icon: "arrow.up.right.square", opensExternally: true),
        ]
        if visibility.showTSite {
            links.append(FriendLink(id: "t", title: "T站", url: DashboardURLs.tDashboard, icon: "globe.asia.australia"))
        }
        return links
    }

    var body: some View {
        ZStack {
            dashboardPageBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    DashboardCard {
                        Text("重要提示：您正在访问友情链接")
                            .font(.headline)
                            .foregroundStyle(.red)
                        Text("友情链接内网站展示的任何内容均与 Dashboard 应用看板无关；Dashboard 应用看板项目组不负责维护友情链接内容。")
                            .font(.subheadline)
                    }

                    linkGroup("Dashboard 应用看板项目组站点", links: projectSites)

                    linkGroup("使用 Dashboard 应用看板信息的应用", links: friendApps)
                    linkGroup("使用 Dashboard 应用看板信息的站点", links: friendSites)
                    linkGroup("其他站点", links: otherSites)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("友情链接")
    }

    private func linkGroup(_ title: String, links: [FriendLink]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            DashboardCard {
                ForEach(Array(links.enumerated()), id: \.element.id) { index, link in
                    Button {
                        open(link)
                    } label: {
                        row(link.title, icon: link.icon, external: link.opensExternally)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(link.packageName == nil ? "打开站点" : "查看原生应用详情")
                    if index < links.count - 1 { Divider() }
                }
            }
        }
    }

    private func open(_ link: FriendLink) {
        if let packageName = link.packageName {
            onOpenModal(.appDetail(.init(packageName: packageName)))
        } else if link.opensExternally, let url = link.url {
            openURL(url)
        } else if let url = link.url {
            onOpenModal(.web(.init(title: link.title, url: url)))
        }
    }

    private func row(_ title: String, icon: String, external: Bool) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Image(systemName: external ? "arrow.up.right" : "chevron.right")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }
}

private struct FriendLink: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL?
    let packageName: String?
    let icon: String
    let opensExternally: Bool

    init(
        id: String,
        title: String,
        url: URL? = nil,
        packageName: String? = nil,
        icon: String,
        opensExternally: Bool = false
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.packageName = packageName
        self.icon = icon
        self.opensExternally = opensExternally
    }
}
