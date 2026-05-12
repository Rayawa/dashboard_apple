import SwiftUI
import WebKit

enum DashboardSegment: String, CaseIterable, Identifiable {
    case t = "T站"
    case s = "S站"

    var id: String { rawValue }

    var endpoint: SiteEndpoint {
        switch self {
        case .t: .t
        case .s: .s
        }
    }
}

enum DashboardSidebarItem: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case projectHome
    case friends
    case contact
    case apiDocs
    case webLog
    case appLog
    case privacy
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "看板主页面"
        case .projectHome: "项目网站首页"
        case .friends: "友情链接"
        case .contact: "联系我们"
        case .apiDocs: "API文档说明"
        case .webLog: "Web更新日志"
        case .appLog: "App更新日志"
        case .privacy: "隐私政策"
        case .about: "应用信息"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: "chart.line.uptrend.xyaxis"
        case .projectHome: "house"
        case .friends: "link"
        case .contact: "person.2"
        case .apiDocs: "doc.text"
        case .webLog: "network"
        case .appLog: "clock.arrow.circlepath"
        case .privacy: "hand.raised"
        case .about: "info.circle"
        }
    }
}

struct DashboardView: View {
    @State private var selectedItem: DashboardSidebarItem? = .dashboard
    @State private var preferredColumn: NavigationSplitViewColumn = .detail
    @State private var segment: DashboardSegment = .s
    @State private var activeModal: AppRoute?
    @State private var webController = WebViewController()
    @State private var showWarn = false
    @State private var showTutorial = false
    @State private var showClearCacheAlert = false
    @State private var searchText = ""
    @State private var searchErrorMessage: String?
    @State private var isSearchingApp = false

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            List {
                Section {
                    sidebarRow(for: .dashboard)
                }

                Section {
                    sidebarRow(for: .projectHome)
                    sidebarRow(for: .friends)
                }

                Section {
                    sidebarRow(for: .contact)
                    sidebarRow(for: .apiDocs)
                    sidebarRow(for: .webLog)
                    sidebarRow(for: .appLog)
                    sidebarRow(for: .privacy)
                    sidebarRow(for: .about)
                }

                Section {
                    Button("清除缓存", systemImage: "trash", role: .destructive) {
                        showClearCacheAlert = true
                    }
                    .font(.subheadline)
                    .labelStyle(.titleAndIcon)
                    .imageScale(.small)
                }
            }
            .environment(\.defaultMinListRowHeight, 34)
            .navigationTitle("鸿蒙应用看板")
            .frame(minWidth: 220)
        } detail: {
            DashboardDetailContent(
                segment: $segment,
                controller: webController,
                onInfo: { showTutorial = true },
                isSearchingApp: isSearchingApp,
                searchText: $searchText,
                onSearchSubmit: submitSearch
            )
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showTutorial) {
            NavigationStack {
                TutorialComponent()
            }
            .dashboardModalCloseToolbar()
        }
        .sheet(item: $activeModal) { route in
            NavigationStack {
                modalView(for: route)
            }
            .dashboardModalCloseToolbar()
        }
        .sheet(isPresented: $showWarn) {
            NavigationStack {
                WarnComponent()
                    .padding()
                    .navigationTitle("重要提示")
                    #if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .dashboardModalCloseToolbar()
        }
        .onAppear {
            if UserDefaults.standard.object(forKey: "has_seen_warn") == nil {
                showWarn = true
                UserDefaults.standard.set(true, forKey: "has_seen_warn")
            }
        }
        .alert("清除缓存", isPresented: $showClearCacheAlert) {
            Button("取消", role: .cancel) {}
            Button("继续", role: .destructive) {
                clearWebCache()
            }
        } message: {
            Text("这会删除当前 WebView 缓存和 Cookie。")
        }
        .alert("搜索失败", isPresented: Binding(get: { searchErrorMessage != nil }, set: { if !$0 { searchErrorMessage = nil } })) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(searchErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func modalView(for route: AppRoute) -> some View {
        switch route {
        case .friends:
            FriendPageView(onOpenModal: openModal)
        case .friendWeb(let payload):
            QueryWeb(payload: payload)
        case .contact:
            ContactComponent()
        case .about:
            AboutPageView(onOpenModal: openModal)
        case .aboutWeb(let payload):
            AboutWebPageView(payload: payload)
        case .queryWeb(let payload):
            QueryWeb(payload: payload)
        case .appLog:
            AppLogPageView()
        case .htmlPage(let payload):
            HTMLPageView(payload: payload)
        }
    }

    private func handleSidebarSelection(_ item: DashboardSidebarItem) {
        selectedItem = .dashboard
        preferredColumn = .detail

        switch item {
        case .dashboard:
            break
        case .projectHome:
            openModal(.queryWeb(.init(title: "项目网站首页", urlString: DashboardURLs.mainPage.absoluteString)))
        case .friends:
            openModal(.friends)
        case .contact:
            openModal(.contact)
        case .apiDocs:
            openModal(.aboutWeb(.init(title: "API文档说明", urlString: DashboardURLs.sBase.appending(path: "docs").absoluteString)))
        case .webLog:
            openModal(.aboutWeb(.init(title: "Web更新日志", urlString: DashboardURLs.tBase.appending(path: "changelog").absoluteString)))
        case .appLog:
            openModal(.appLog)
        case .privacy:
            openModal(.htmlPage(.init(title: "隐私政策", resourceName: "privacy")))
        case .about:
            openModal(.about)
        }
    }

    private func openModal(_ route: AppRoute) {
        activeModal = route
    }

    private func sidebarRow(for item: DashboardSidebarItem) -> some View {
        Button {
            handleSidebarSelection(item)
        } label: {
            Label(item.title, systemImage: item.symbolName)
                .font(.subheadline)
                .imageScale(.small)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func clearWebCache() {
        let store = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        store.fetchDataRecords(ofTypes: types) { records in
            store.removeData(ofTypes: types, for: records) {}
        }
    }

    private func submitSearch() {
        let value = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !isSearchingApp else { return }
        preferredColumn = .detail
        Task {
            await searchAppAndOpenResult(named: value)
        }
    }

    @MainActor
    private func searchAppAndOpenResult(named name: String) async {
        isSearchingApp = true
        defer { isSearchingApp = false }
        do {
            let appID = try await AppAPIService.appId(byName: name)
            guard try await AppAPIService.verify(appId: appID) else {
                throw APIError.notFound("库中未找到该应用")
            }
            preferredColumn = .detail
            openModal(.queryWeb(.init(title: name, urlString: AppAPIService.resultURL(for: appID).absoluteString)))
            searchText = ""
        } catch {
            searchErrorMessage = error.localizedDescription
        }
    }
}

private struct DashboardDetailContent: View {
    @Binding var segment: DashboardSegment
    let controller: WebViewController
    let onInfo: () -> Void
    let isSearchingApp: Bool
    @Binding var searchText: String
    let onSearchSubmit: () -> Void

    var body: some View {
        ZStack {
            dashboardPageBackground
            Web(
                url: segment.endpoint.url,
                controller: controller
            )
            .ignoresSafeArea(edges:[.top, .bottom])
            .id(segment.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(dashboardPageBackground)
            WebLoadingProgressView(controller: controller)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(edges:[.top, .bottom])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: toolbarLeadingPlacement) {
                Button {
                    controller.goBack()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .disabled(!controller.canGoBack)
            }

            ToolbarItemGroup(placement: toolbarTrailingPlacement) {
                Button("Info", systemImage: "info") {
                    onInfo()
                }

                ControlGroup {
                    Menu {
                        ForEach(DashboardSegment.allCases) { item in
                            Button {
                                segment = item
                            } label: {
                                HStack {
                                    Text(item.rawValue)
                                    if item == segment {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "globe")
                    }

                    ShareLink(item: segment.endpoint.url)
                }

                toolbarSearchField
            }
        }
        .toolbar(removing: .title)
    }

    private var toolbarSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索应用名称", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit(onSearchSubmit)

            if isSearchingApp {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(width: searchFieldWidth)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }

    private var toolbarLeadingPlacement: ToolbarItemPlacement {
#if os(macOS)
        .navigation
#else
        .topBarLeading
#endif
    }

    private var toolbarTrailingPlacement: ToolbarItemPlacement {
#if os(macOS)
        .automatic
#else
        .topBarTrailing
#endif
    }

    private var searchFieldWidth: CGFloat {
#if os(macOS)
        260
#else
        190
#endif
    }
}

#Preview {
    DashboardView()
}
