import SwiftUI

struct TutorialComponent: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 290, maximum: 520), spacing: 16)],
                    alignment: .leading,
                    spacing: 16
                ) {
                    TutorialCard(title: "首页总览", systemImage: "chart.bar.xaxis") {
                        tutorialSection(items: [
                            "查看应用、元服务、开发者和数据总量，以及后端同步状态。",
                            "查看最近更新应用、开发者排行和服务端允许展示的下载榜。",
                            "点击应用卡片直接进入原生详情；下拉即可刷新。",
                        ])
                    }

                    TutorialCard(title: "应用与图表", systemImage: "square.grid.2x2") {
                        tutorialSection(items: [
                            "“概览”展示评分、最低 SDK、目标 SDK 与 API 版本历史图表。",
                            "轻点或拖动图表可读取具体数据；长时间序列支持横向滚动。",
                            "“全部应用”支持类型过滤、字段搜索、排序、分页和 AND / OR 高级筛选。",
                        ])
                    }

                    TutorialCard(title: "搜索与详情", systemImage: "magnifyingglass") {
                        tutorialSection(items: [
                            "可输入应用名称、包名、App ID，或粘贴应用市场与看板链接。",
                            "详情页包含身份信息、版本与 SDK、评分分布、截图、介绍和更新内容。",
                            "下载与评分趋势支持拖动选点和时间范围缩放；敏感下载数据遵循服务端展示开关。",
                        ])
                    }

                    TutorialCard(title: "投稿与更新", systemImage: "square.and.arrow.up") {
                        tutorialSection(items: [
                            "在“我的”中打开“投稿应用”，提交包名或 App ID 以触发抓取或更新。",
                            "用户名只用于投稿备注，留空也可使用；提交结果会在应用内明确提示。",
                            "刷新失败时会优先显示最近的本地缓存，并标明缓存时间。",
                        ])
                    }

                    TutorialCard(title: "备用网页与友链", systemImage: "globe") {
                        tutorialSection(items: [
                            "原生首页、应用和搜索是主要入口；“备用网页”用于接口异常时临时访问站点。",
                            "T 站和下载相关数据仅在服务端允许时显示。",
                            "友链应用会进入原生详情；第三方站点内容由各自维护者负责。",
                        ])
                    }

                    TutorialCard(title: "设置、缓存与隐私", systemImage: "gearshape") {
                        tutorialSection(items: [
                            "“我的”中可清除 API 缓存、网页存储与 Cookie，用户名和偏好设置会保留。",
                            "重要提示、隐私政策、更新日志和联系方式均可在“我的”中再次查看。",
                            "iPhone 使用紧凑导航，iPad 与 Mac 使用分栏导航；功能与数据保持一致。",
                        ])
                    }

                    TutorialCard(title: "联系与反馈", systemImage: "person.2") {
                        tutorialSection(items: [
                            "使用中遇到问题、发现信息异常，或有功能建议，可通过“我的 → 联系我们”获取联系方式。",
                            "点击邮箱或群号条目即可复制；赞助入口会交给系统浏览器打开。",
                        ])
                        NavigationLink(value: AppRoute.contact) {
                            Label("打开联系我们", systemImage: "chevron.right")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                warningBlock(
                    "数据说明",
                    text: "所有市场数据来自华为应用市场公开信息，仅供参考，不保证来源的准确性、完整性或实时性。"
                )
            }
            .padding()
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .navigationTitle("使用教程")
    }

    private var header: some View {
        DashboardCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 18) { headerContent }
                VStack(alignment: .leading, spacing: 14) { headerContent }
            }
        }
    }

    @ViewBuilder
    private var headerContent: some View {
        Image(systemName: "sparkles.rectangle.stack.fill")
            .font(.system(size: 46, weight: .semibold))
            .foregroundStyle(.blue.gradient)
            .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 7) {
            Text("欢迎使用 Dashboard 应用看板")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Apple 原生版覆盖数据总览、应用列表、图表分析、搜索、详情、投稿与个人设置；网页只保留为备用入口。")
                .foregroundStyle(.secondary)
            Button("访问项目网站", systemImage: "arrow.up.right.square") {
                openURL(DashboardURLs.mainPage)
            }
            #if os(ios)
            .buttonStyle(.link)
            #endif
        }
    }

    private func tutorialSection(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.cyan)
                        .padding(.top, 2)
                        .accessibilityHidden(true)
                    Text(item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func warningBlock(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "exclamationmark.triangle.fill")
                .font(.headline.weight(.bold))
            Text(text)
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TutorialCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                Label(title, systemImage: systemImage)
                    .font(.title2.bold())
                    .foregroundStyle(.tint)
                content
            }
        }
    }
}
