import SwiftUI
import WebKit

struct NativeProfileView: View {
    @AppStorage("username") private var username = ""
    @AppStorage("haptic_level") private var hapticLevel = 1
    @State private var cacheSize: Int64 = 0
    @State private var showClearConfirmation = false
    @State private var showWarning = false
    @State private var cacheMessage: String?
    @State private var contentWidth: CGFloat = 0

    var body: some View {
        Group {
            if contentWidth >= 840 {
                wideLayout
            } else {
                compactLayout
            }
        }
        .frame(maxWidth: 1_440, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .dashboardPage()
        .navigationTitle("我的")
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            contentWidth = width
        }
        .task { cacheSize = await AppAPIService.apiCacheSize() }
        .confirmationDialog("清除缓存", isPresented: $showClearConfirmation) {
            Button("清除 API 缓存、网页存储与 Cookie", role: .destructive) {
                DashboardFeedback.selection()
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

    private var wideLayout: some View {
        HStack(spacing: 0) {
            VStack(spacing: 14) {
                Spacer(minLength: 28)
                identity
                Divider()
                versionInformation
                Spacer(minLength: 28)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 440, maxHeight: .infinity)

            Divider()

            ScrollView {
                sections
                    .padding(.horizontal, 14)
                    .padding(.vertical, 28)
                    .padding(.bottom, 72)
            }
            .frame(maxWidth: 720, maxHeight: .infinity)
        }
    }

    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 14) {
                identity
                    .padding(.vertical, 18)
                Divider()
                sections
                Divider()
                versionInformation
                    .padding(.top, 4)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 92)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
    }

    private var identity: some View {
        VStack(spacing: 8) {
            Image("DashboardBrand")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityHidden(true)
            Text("Dashboard 应用看板")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            Text("Apple 原生版")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var versionInformation: some View {
        VStack(spacing: 5) {
            Text("版本 \(DashboardMeta.appVersion)")
            Text("Designed & Developed by Ray Chen (Rayawa)")
            Text("Copyright © 2026. All rights reserved.")
            Text("本应用备案域名：rayawa.top")
            Link("京ICP备2025153453号", destination: DashboardURLs.miit)
                .simultaneousGesture(TapGesture().onEnded { DashboardFeedback.selection() })
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var sections: some View {
        VStack(spacing: 14) {
            settingsSection

            Divider().padding(.vertical, 2)

            linkSection(title: "功能", systemImage: "square.grid.2x2.fill", routes: [
                ("投稿应用", "square.and.arrow.up", .submitApp),
                ("友情链接", "link", .friends),
                ("查看教程", "questionmark.circle", .tutorial),
            ])

            Divider().padding(.vertical, 2)

            ProfileSection(title: "更多", systemImage: "ellipsis.circle.fill") {
                externalLink("项目网站首页", asset: "DashboardBrand", url: DashboardURLs.mainPage)
                profileDivider
                externalLink("订阅 MeoW 频道", asset: "MeoW", url: DashboardURLs.meowChannel)
                profileDivider
                navigationLink("API 文档说明", icon: "doc.text", route: .web(.init(title: "API 文档说明", url: DashboardURLs.apiDocs)))
                profileDivider
                navigationLink("Web 更新日志", icon: "network", route: .web(.init(title: "Web 更新日志", url: DashboardURLs.webChangeLog)))
                profileDivider
                externalLink("赞助我们", icon: "heart", url: DashboardURLs.sponsor)
            }

            Divider().padding(.vertical, 2)

            ProfileSection(title: "帮助", systemImage: "questionmark.circle.fill") {
                Button {
                    DashboardFeedback.selection()
                    showWarning = true
                } label: {
                    profileRow("重要提示", icon: "exclamationmark.triangle")
                }
                .buttonStyle(.plain)
                profileDivider
                navigationLink("App 更新日志", icon: "clock.arrow.circlepath", route: .appLog)
                profileDivider
                navigationLink("隐私政策", icon: "hand.raised", route: .htmlPage(.init(title: "隐私政策", resourceName: "privacy")))
                profileDivider
                navigationLink("联系我们", icon: "person.2", route: .contact)
                profileDivider
                navigationLink("开发者信息", icon: "hammer", route: .developer)
            }
        }
    }

    private var settingsSection: some View {
        ProfileSection(title: "设置", systemImage: "gearshape.fill") {
            HStack(spacing: 12) {
                profileIcon("person.text.rectangle")
                Text("用户名")
                Spacer(minLength: 12)
                TextField("可选", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 60)

            profileDivider

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    Label {
                        Text("振动强度")
                    } icon: {
                        profileIcon("waveform.path")
                    }
                    Spacer(minLength: 12)
                    HapticLevelControl(level: $hapticLevel)
                        .frame(width: 230)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text("振动强度")
                    } icon: {
                        profileIcon("waveform.path")
                    }
                    HapticLevelControl(level: $hapticLevel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 78)

            profileDivider

            Button(role: .destructive) {
                DashboardFeedback.selection()
                showClearConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    profileIcon("trash", tint: .red)
                    Text("清除缓存")
                    Spacer()
                    Text(DashboardFormat.bytes(cacheSize)).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 54)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func linkSection(title: String, systemImage: String, routes: [(String, String, AppRoute)]) -> some View {
        ProfileSection(title: title, systemImage: systemImage) {
            ForEach(Array(routes.enumerated()), id: \.offset) { index, item in
                navigationLink(item.0, icon: item.1, route: item.2)
                if index < routes.count - 1 { profileDivider }
            }
        }
    }

    private func navigationLink(_ title: String, icon: String, route: AppRoute) -> some View {
        NavigationLink(value: route) {
            profileRow(title, icon: icon)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { DashboardFeedback.selection() })
    }

    private func externalLink(_ title: String, icon: String? = nil, asset: String? = nil, url: URL) -> some View {
        Link(destination: url) {
            profileRow(title, icon: icon, asset: asset, external: true)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { DashboardFeedback.selection() })
    }

    private func profileRow(_ title: String, icon: String? = nil, asset: String? = nil, external: Bool = false) -> some View {
        HStack(spacing: 12) {
            if let asset {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
            } else if let icon {
                profileIcon(icon)
            }
            Text(title)
            Spacer()
            Image(systemName: external ? "arrow.up.right" : "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 54)
        .contentShape(Rectangle())
    }

    private func profileIcon(_ name: String, tint: Color = .accentColor) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)
    }

    private var profileDivider: some View {
        Divider().padding(.leading, 56).padding(.trailing, 16)
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

private struct ProfileSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.primary.opacity(0.07), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.055), radius: 8, y: 2)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct HapticLevelControl: View {
    @Binding var level: Int

    private let labels = ["关闭", "灵动", "硬朗"]

    var body: some View {
        VStack(spacing: 2) {
            Slider(value: sliderValue, in: 0...2, step: 1)
                .accessibilityLabel("振动强度")
                .accessibilityValue(labels[safe: level] ?? labels[1])
            HStack(spacing: 0) {
                ForEach(Array(labels.enumerated()), id: \.offset) { value, label in
                    Button {
                        select(value)
                    } label: {
                        Text(label)
                            .font(.caption2.weight(level == value ? .semibold : .regular))
                            .foregroundStyle(level == value ? Color.accentColor : Color.secondary)
                            .frame(maxWidth: .infinity, minHeight: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label)振动")
                    .accessibilityAddTraits(level == value ? .isSelected : [])
                }
            }
        }
    }

    private var sliderValue: Binding<Double> {
        Binding(
            get: { Double(min(max(level, 0), 2)) },
            set: { select(Int($0.rounded())) }
        )
    }

    private func select(_ value: Int) {
        let nextLevel = min(max(value, 0), 2)
        guard nextLevel != level else {
            DashboardFeedback.preview(level: nextLevel)
            return
        }
        level = nextLevel
        DashboardFeedback.preview(level: nextLevel)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
