import SwiftUI

struct FriendPageView: View {
    let onOpenModal: (AppRoute) -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.dashboardVisibility) private var visibility

    private let friendSites: [FriendLink] = [
        .init(id: "hap", title: "Hap资源站", url: DashboardURLs.hapStore, icon: .asset("HapStore")),
        .init(id: "dz", title: "应用荟萃", url: DashboardURLs.dzTap, icon: .asset("DZTap")),
        .init(id: "open", title: "Open Store", url: DashboardURLs.openStore, icon: .asset("OpenStore")),
        .init(id: "next", title: "NEXT Store", url: DashboardURLs.nextStore, icon: .asset("NextStore")),
        .init(id: "fangzhou", title: "方舟网", url: DashboardURLs.fangzhou, icon: .system("ferry")),
    ]

    private let friendApps: [FriendLink] = [
        .init(id: "getrace", title: "迹得", packageName: "cn.biandangroup.getrace", icon: .asset("JiDe")),
        .init(id: "subscribe", title: "记得订阅", packageName: "com.xxtstudio.accountDL", icon: .asset("Subscription")),
        .init(id: "subscribe-atomic", title: "记得订阅（元服务）", packageName: "com.atomicservice.6917600885144283966", icon: .asset("SubscriptionAtomic")),
        .init(id: "paper-talk", title: "纸语", packageName: "com.my.papertalk", icon: .asset("PaperTalk")),
    ]

    private let otherSites: [FriendLink] = [
        .init(id: "ag", title: "AppGallery统计数据", url: DashboardURLs.agStatistics, icon: .system("chart.bar"))
    ]

    private var projectSites: [FriendLink] {
        var links = [
            FriendLink(id: "project", title: "项目网站首页", url: DashboardURLs.mainPage, icon: .asset("DashboardBrand")),
            FriendLink(id: "s", title: "S站", url: DashboardURLs.sBase, icon: .asset("DashboardBrand")),
            FriendLink(id: "egui", title: "Egui", url: DashboardURLs.eguiBase, icon: .asset("DashboardBrand"), opensExternally: true),
        ]
        if visibility.showTSite {
            links.append(FriendLink(id: "t", title: "T站", url: DashboardURLs.tDashboard, icon: .asset("DashboardBrand")))
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

    private func row(_ title: String, icon: FriendIcon, external: Bool) -> some View {
        HStack(spacing: 10) {
            switch icon {
            case .system(let name):
                Image(systemName: name)
                    .foregroundStyle(.tint)
                    .frame(width: 28)
                    .accessibilityHidden(true)
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
            }
            Text(title)
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
    let icon: FriendIcon
    let opensExternally: Bool

    init(
        id: String,
        title: String,
        url: URL? = nil,
        packageName: String? = nil,
        icon: FriendIcon,
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

private enum FriendIcon: Hashable {
    case system(String)
    case asset(String)
}
