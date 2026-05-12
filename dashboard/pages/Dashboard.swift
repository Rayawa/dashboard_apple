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
        case .dashboard: "应用看板"
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
        case .dashboard: "building.columns"
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
    @State private var path: [AppRoute] = []
    @State private var webController = WebViewController()
    @State private var showWarn = false
    @State private var showTutorial = false
    @State private var showClearCacheAlert = false
    @State private var searchText = ""
    @State private var searchErrorMessage: String?
    @State private var isSearchingApp = false

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            List(selection: $selectedItem) {
                Section {
                    ForEach(DashboardSidebarItem.allCases) { item in
                        NavigationLink(value: item) {
                            Label(item.title, systemImage: item.symbolName)
                        }
                    }
                }

                Section {
                    Button("清除缓存", systemImage: "trash", role: .destructive) {
                        showClearCacheAlert = true
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationDestination(for: DashboardSidebarItem.self) { item in
                NavigationStack(path: $path) {
                    detailView(for: item)
                }
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
            }
            .frame(minWidth: 220)
        } detail: {
            NavigationStack(path: $path) {
                detailView(for: selectedItem ?? .dashboard)
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(isPresented: $showTutorial) {
            NavigationStack {
                TutorialComponent()
            }
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
    private func detailView(for item: DashboardSidebarItem) -> some View {
        switch item {
        case .dashboard:
            DashboardDetailContent(
                segment: $segment,
                controller: webController,
                onInfo: { showTutorial = true },
                isSearchingApp: isSearchingApp,
                searchText: $searchText,
                onSearchSubmit: submitSearch
            )
        case .projectHome:
            QueryWeb(payload: .init(title: "项目网站首页", urlString: DashboardURLs.mainPage.absoluteString))
        case .friends:
            FriendPageView(onNavigate: navigate)
        case .contact:
            ContactComponent()
        case .apiDocs:
            AboutWebPageView(payload: .init(title: "API文档说明", urlString: DashboardURLs.sBase.appending(path: "docs").absoluteString))
        case .webLog:
            AboutWebPageView(payload: .init(title: "Web更新日志", urlString: DashboardURLs.tBase.appending(path: "changelog").absoluteString))
        case .appLog:
            AppLogPageView()
        case .privacy:
            HTMLPageView(payload: .init(title: "隐私政策", resourceName: "privacy"))
        case .about:
            AboutPageView(onNavigate: navigate)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .user:
            UserPageView(onNavigate: navigate)
        case .submit:
            AppSubmitComponent()
        case .query(let initialText):
            AppQueryComponent(initialText: initialText) { payload in
                path.append(.queryWeb(payload))
            }
        case .friends:
            FriendPageView(onNavigate: navigate)
        case .friendWeb(let payload):
            QueryWeb(payload: payload)
        case .contact:
            ContactComponent()
        case .about:
            AboutPageView(onNavigate: navigate)
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

    private func navigate(_ route: AppRoute) {
        path.append(route)
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
            path.append(.queryWeb(.init(title: name, urlString: AppAPIService.resultURL(for: appID).absoluteString)))
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
        GeometryReader { proxy in
                    Web(
                        url: segment.endpoint.url,
                        controller: controller
                    )
                    .ignoresSafeArea()
                    .id(segment.id)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: max(proxy.size.height, 640))
                    .background(dashboardBackgroundColor)
                    .flexibleHeaderContent(minHeight: max(proxy.size.height, 640))

        }
        .toolbar {
            ToolbarItem(placement: toolbarLeadingPlacement) {
                Button {
                    controller.goBack()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .disabled(!controller.canGoBack)
            }

            ToolbarItem(placement: .principal) {
                segmentPicker
            }

            ToolbarSpacer(.flexible)

            ToolbarItem {
                ShareLink(item: segment.endpoint.url)
            }

            ToolbarSpacer(.fixed)

            ToolbarItem {
                Button("Info", systemImage: "info") {
                    onInfo()
                }
            }

            ToolbarSpacer(.fixed)

            ToolbarItem {
                toolbarSearchField
            }
        }
        .toolbar(removing: .title)
        .ignoresSafeArea()
    }

    private var dashboardBackgroundColor: Color {
#if os(iOS)
        Color(uiColor: .systemBackground)
#elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
#endif
    }

    private var segmentPicker: some View {
        Picker("站点", selection: $segment) {
            ForEach(DashboardSegment.allCases) { item in
                Text(item.rawValue).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
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
