import SwiftUI

struct TutorialComponent: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        TabView {
            TutorialCard(title: "欢迎来到Hm应用看板", systemImage: "sparkles") {
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        openURL(DashboardURLs.mainPage)
                    } label: {
                        Label("项目总网页", systemImage: "safari")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.blue)
                            .underline()
                    }
                    .buttonStyle(.plain)

                    Text("本应用是由 Harmony Dashboard 项目组直接参与编写的鸿蒙应用。应用收集华为应用市场的公开数据，转化为直观的图表与报告。简单来说，您能在这里查看几乎所有鸿蒙应用的动态。")

                    tutorialSection("功能概览", items: [
                        "数据总览与图表分析：通过榜单、饼图与折线图，直观查看应用下载量、评分趋势与市场分布。",
                        "搜索应用与查看详情：支持按名称、评分等条件搜索排序、应用内搜索应用、分享链接搜索应用。",
                        "数据定时自动更新：后台每 30 分钟同步一次数据。",
                        "交互式操作与分享：点击图表可筛选数据，点击应用可进入详情页，也可通过链接分享页面。",
                        "投稿更新应用信息：可通过应用市场分享与菜单页投稿新应用或更新应用信息。"
                    ])

                    warningBlock("重要提示", text: "本应用的所有数据均来源于华为应用市场的公开信息，数据仅供参考，不保证来源的准确性、完整性和真实性。")
                }
            }

            TutorialCard(title: "主界面", systemImage: "rectangle.portrait.tophalf.inset.filled") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("您可以在顶部切换喜欢的站点。")
                        .font(.headline)

                    tutorialSection("主要功能", items: [
                        "数据统计：展示应用总数、元服务总数、开发者总数等关键指标。",
                        "下载榜：提供下载量排名前 20 的应用列表，以及排除华为系应用后的排名。",
                        "应用详情：点击任意应用相关入口查看详细信息，包括下载量、评分、支持设备、版本信息等。",
                        "趋势分析：展示应用下载量变化趋势和增量趋势图表。",
                        "应用列表：支持搜索、排序、筛选。"
                    ])

                    tutorialSection("使用说明", items: [
                        "刷新数据：页面内下拉或站点内操作获取最新数据。",
                        "搜索应用：支持按名称、包名、开发者等搜索。",
                        "快速筛选：点击组件可快速查看对应应用。",
                        "排序功能：按评分、下载量、大小等排序。",
                        "查看详情：点击应用行查看详细信息。",
                        "过滤选项：可排除华为/元服务应用。"
                    ])
                }
            }

            TutorialCard(title: "投稿与查询功能", systemImage: "square.and.pencil") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("投稿功能可以触发应用抓取与更新。您可以通过 App 内“投稿应用”，或在应用市场中“分享应用至看板”来投稿新的 App 或更新 App 信息。")

                    Text("在“查询应用”输入应用信息可以查询应用的具体数据，您也可以在应用市场里“分享应用链接至看板”查询信息。")

                    highlightedBlock("AI 智能提取", text: "投稿与查询功能支持 AI 智能提取，将应用信息输入或粘贴进文本框即可自动提取。")

                    tutorialSection("常用方式", items: [
                        "应用商店投稿与查询：在任意 App 详情页点击分享并选择应用看板进行投稿与查询。",
                        "应用内投稿与查询：在菜单内进入“投稿应用”或“查询应用”。"
                    ])
                }
            }

            TutorialCard(title: "友情链接与分享功能", systemImage: "link") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("您可以在主界面的菜单中访问友情链接。")

                    warningBlock("友情链接提示", text: "友情链接内网站展示的任何内容均与 Hm 应用看板无关，Harmony Dashboard 项目组不负责维护友情链接内容。")

                    tutorialSection("分享方式", items: [
                        "链接分享：在主界面点击分享按钮分享当前页面链接。",
                        "站内打开：可从菜单进入项目网站首页、API 文档和更新日志。",
                        "跨设备分享：鸿蒙版支持碰一碰和隔空传送分享当前页面链接。AppleOS 版当前保留普通链接分享入口。"
                    ])
                }
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .always))
        #endif
        .background(
            dashboardPageBackground.ignoresSafeArea()
        )
        .navigationTitle("教程")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func tutorialSection(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.bold))

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.cyan)
                        .padding(.top, 2)

                    Text(item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func warningBlock(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "exclamationmark.triangle.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(.red)

            Text(text)
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func highlightedBlock(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.bold))
            Text(text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.18), Color.blue.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}

private struct TutorialCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white.opacity(0.7))
                            .frame(width: 52, height: 52)

                        Image(systemName: systemImage)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.blue)
                    }

                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }

                content
                    .font(.body)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
    }
}
