import SwiftUI

struct WarnComponent: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            dashboardPageBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("重要提示")
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                    Text("Harmony Gallery数据来源于网络，不保证来源准确性、完整性和真实性，仅供参考。")
                        .foregroundStyle(.red)
                    Button("详情查看：项目总网页") {
                        openURL(DashboardURLs.mainPage)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)

                    Group {
                        Text("【架构限制】").bold()
                        Text("数据内容仅覆盖HarmonyOS 5+核心环境，不含侧载或企业定制版应用。")
                        Text("【更新延迟】").bold()
                        Text("数据存在滞后性，同步质量受限于用户网络稳定性，项目组不保证信息的即时性。")
                        Text("【免责申明】").bold()
                        Text("所有数据由第三方测算，不代表华为官方立场。")
                        Text("项目组不对数据来源的准确性、完整性与真实性做任何法律担保。")
                        Text("【知识产权】").bold()
                        Text("算法原创，严禁商用。使用API对接数据库前请先与我们取得联系。")
                        Text("【动态调整】").bold()
                        Text("本项目组拥有对本统计方法论及数据口径的最终解释权。")
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        }
    }
}
