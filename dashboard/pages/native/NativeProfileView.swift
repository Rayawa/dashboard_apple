import SwiftUI
import WebKit

struct NativeProfileView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("username") private var username = ""
    @AppStorage("haptic_level") private var hapticLevel = 1
    @State private var cacheSize: Int64 = 0
    @State private var showClearConfirmation = false
    @State private var showWarning = false
    @State private var cacheMessage: String?

    var body: some View {
        ScrollView {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 28) {
                    identity.frame(maxWidth: 390)
                    sections.frame(maxWidth: 620)
                }
                VStack(spacing: 20) {
                    identity
                    sections
                }
            }
            .padding()
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .navigationTitle("我的")
        .task { cacheSize = await AppAPIService.apiCacheSize() }
        .onChange(of: hapticLevel) {
            DashboardFeedback.selection(level: hapticLevel)
        }
        .confirmationDialog("清除缓存", isPresented: $showClearConfirmation) {
            Button("清除 API 缓存、网页存储与 Cookie", role: .destructive) {
                Task { await clearCache() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("用户名和设置会保留。")
        }
        .alert("缓存", isPresented: Binding(get: { cacheMessage != nil }, set: { if !$0 { cacheMessage = nil } })) {
            Button("确定", role: .cancel) {}
        } message: { Text(cacheMessage ?? "") }
        .sheet(isPresented: $showWarning) {
            NavigationStack {
                WarnComponent().padding().navigationTitle("重要提示")
            }
            .dashboardModalCloseToolbar()
            .dashboardModalFrame(.warning)
        }
    }

    private var identity: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 82))
                .foregroundStyle(.tint)
            Text("Dashboard 应用看板")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Apple 原生版")
                .font(.title3.weight(.semibold)).foregroundStyle(.secondary)
            Spacer(minLength: 10)
            Text("版本 \(DashboardMeta.appVersion)").font(.footnote).foregroundStyle(.secondary)
            Text("Designed & Developed by Ray Chen (Rayawa)").font(.footnote).foregroundStyle(.secondary)
            Text("Copyright © 2026. All rights reserved.").font(.footnote).foregroundStyle(.secondary)
            Text("本应用备案域名：rayawa.top").font(.footnote).foregroundStyle(.secondary)
            Link("京ICP备2025153453号", destination: DashboardURLs.miit).font(.footnote)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var sections: some View {
        VStack(spacing: 20) {
            DashboardCard {
                Text("设置").font(.headline).padding(.bottom, 8)
                LabeledContent("用户名") {
                    TextField("可选", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 220)
                }
                Divider()
                Picker("触感反馈", selection: $hapticLevel) {
                    Text("关闭").tag(0)
                    Text("轻柔").tag(1)
                    Text("明显").tag(2)
                }
                Divider()
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    HStack {
                        Label("清除缓存", systemImage: "trash")
                        Spacer()
                        Text(DashboardFormat.bytes(cacheSize)).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            linkSection(title: "功能", routes: [
                ("搜索应用", "magnifyingglass", .search),
                ("投稿应用", "square.and.arrow.up", .submitApp),
                ("友情链接", "link", .friends),
                ("查看教程", "questionmark.circle", .tutorial),
            ])

            DashboardCard {
                Text("更多").font(.headline).padding(.bottom, 8)
                externalLink("项目网站首页", icon: "house", url: DashboardURLs.mainPage)
                Divider()
                externalLink("订阅 MeoW 频道", icon: "bubble.left.and.bubble.right", url: DashboardURLs.meowChannel)
                Divider()
                NavigationLink(value: AppRoute.web(.init(title: "API 文档说明", url: DashboardURLs.apiDocs))) {
                    row("API 文档说明", icon: "doc.text")
                }.buttonStyle(.plain)
                Divider()
                NavigationLink(value: AppRoute.web(.init(title: "Web 更新日志", url: DashboardURLs.webChangeLog))) {
                    row("Web 更新日志", icon: "network")
                }.buttonStyle(.plain)
                Divider()
                externalLink("赞助我们", icon: "heart", url: DashboardURLs.sponsor)
            }

            DashboardCard {
                Text("帮助").font(.headline).padding(.bottom, 8)
                Button { showWarning = true } label: { row("重要提示", icon: "exclamationmark.triangle") }.buttonStyle(.plain)
                Divider()
                NavigationLink(value: AppRoute.appLog) { row("App 更新日志", icon: "clock.arrow.circlepath") }.buttonStyle(.plain)
                Divider()
                NavigationLink(value: AppRoute.htmlPage(.init(title: "隐私政策", resourceName: "privacy"))) {
                    row("隐私政策", icon: "hand.raised")
                }.buttonStyle(.plain)
                Divider()
                NavigationLink(value: AppRoute.contact) { row("联系我们", icon: "person.2") }.buttonStyle(.plain)
                Divider()
                NavigationLink(value: AppRoute.developer) { row("开发者信息", icon: "hammer") }.buttonStyle(.plain)
            }
        }
    }

    private func linkSection(title: String, routes: [(String, String, AppRoute)]) -> some View {
        DashboardCard {
            Text(title).font(.headline).padding(.bottom, 8)
            ForEach(Array(routes.enumerated()), id: \.offset) { index, item in
                NavigationLink(value: item.2) { row(item.0, icon: item.1) }.buttonStyle(.plain)
                if index < routes.count - 1 { Divider() }
            }
        }
    }

    private func externalLink(_ title: String, icon: String, url: URL) -> some View {
        Link(destination: url) { row(title, icon: icon, external: true) }.buttonStyle(.plain)
    }

    private func row(_ title: String, icon: String, external: Bool = false) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Image(systemName: external ? "arrow.up.right" : "chevron.right").foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }

    @MainActor
    private func clearCache() async {
        do {
            try await AppAPIService.clearAPICache()
            let store = WKWebsiteDataStore.default()
            let records: [WKWebsiteDataRecord] = await withCheckedContinuation { continuation in
                store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) {
                    continuation.resume(returning: $0)
                }
            }
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                    continuation.resume()
                }
            }
            cacheSize = 0
            cacheMessage = "缓存已完全清除"
        } catch {
            cacheMessage = "缓存清理失败：\(error.localizedDescription)"
        }
    }
}
