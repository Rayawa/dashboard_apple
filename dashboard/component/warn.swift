import SwiftUI

struct WarningTextContent: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dashboard 应用看板信息来源于公开网络")
                .font(.headline)
                .foregroundStyle(.red)
            Text("不保证来源的准确性、完整性和真实性，所有信息仅供参考。所有信息不代表任何平台官方立场，项目组不承担用户因采信结果产生的损失。")
            Button("详情查看：项目总网页") {
                openURL(DashboardURLs.mainPage)
            }
            #if os(macos)
            .buttonStyle(.link)
            #endif

            notice("数据口径", "应用看板整理应用、SDK、版本、分类、评分及历史快照。下载量、每日最高下载量和增长榜由后端按期同步的公开快照计算。")
            notice("收录范围", "仅收录已正式公开发布的应用与元服务，不包含侧载、公开测试或邀请测试内容。")
            notice("更新延迟", "数据同步可能受更新间隔、数据源变化和网络状态影响，项目组不保证信息的即时性。")
            notice("外部内容", "应用市场详情、项目网站、友情链接、社区频道和赞助页由对应第三方提供，请以目标页面的条款与数据为准。")
            notice("品牌表述", "产品、平台和公司名称仅用于说明数据来源或跳转目标，不表示本项目与其存在合作、授权或官方关联。")
            notice("知识产权", "算法原创，严禁商用。使用 API 对接数据库前请先与项目组取得联系。")
            notice("动态调整", "项目组保留修正统计方法与数据口径的权利。重要决策请回到原始信息页面复核。")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func notice(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("【\(title)】").bold()
            Text(text)
        }
        .font(.subheadline)
    }
}

struct WarnComponent: View {
    var body: some View {
        ZStack {
            dashboardPageBackground.ignoresSafeArea()
            ScrollView {
                WarningTextContent().padding(16)
            }
        }
    }
}
