import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case apps
    case search
    case webBackup
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "首页"
        case .apps: "应用"
        case .search: "搜索"
        case .webBackup: "备用网页"
        case .profile: "我的"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .apps: "square.grid.2x2"
        case .search: "magnifyingglass"
        case .webBackup: "globe"
        case .profile: "person.crop.circle"
        }
    }
}

struct DashboardView: View {
    @State private var selection: DashboardSection = .home
    @State private var path: [AppRoute] = []
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var compactColumn: NavigationSplitViewColumn = .detail
    @State private var visibility = DashboardVisibilityConfig.restricted
    @AppStorage("accepted_important_notice_v3") private var acceptedNotice = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: $compactColumn) {
            List {
                Section("原生看板") {
                    sidebarButton(.home)
                    sidebarButton(.apps)
                    sidebarButton(.search)
                }
                Section("其他") {
                    sidebarButton(.webBackup)
                    sidebarButton(.profile)
                }
            }
            .navigationTitle("Dashboard")
            .navigationSplitViewColumnWidth(min: 210, ideal: 250, max: 310)
        } detail: {
            NavigationStack(path: $path) {
                Group {
                    if acceptedNotice {
                        selectedContent
                    } else {
                        dashboardPageBackground.ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
                }
                    .navigationDestination(for: AppRoute.self, destination: destination)
            }
            .id(selection)
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.dashboardVisibility, visibility)
        .task(id: acceptedNotice) {
            guard acceptedNotice else { return }
            visibility = await AppAPIService.dashboardConfig()
        }
        .onChange(of: selection) {
            path.removeAll()
            compactColumn = .detail
        }
        .onOpenURL(perform: openDeepLink)
        .importantNoticeGate(isPresented: Binding(
            get: { !acceptedNotice },
            set: { _ in }
        )) {
            acceptedNotice = true
        }
    }

    private func openDeepLink(_ url: URL) {
        guard let target = DashboardDeepLink.appTarget(from: url) else { return }
        selection = .search
        compactColumn = .detail
        path = [.appDetail(target)]
    }

    private func sidebarButton(_ section: DashboardSection) -> some View {
        Button {
            DashboardFeedback.selection()
            selection = section
            compactColumn = .detail
        } label: {
            Label(section.title, systemImage: section.symbol)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selection == section ? Color.accentColor.opacity(0.12) : Color.clear)
        .accessibilityAddTraits(selection == section ? .isSelected : [])
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selection {
        case .home: HomeDashboardView()
        case .apps: MarketAppsView()
        case .search: NativeSearchView()
        case .webBackup: WebBackupView()
        case .profile: NativeProfileView()
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .appDetail(let target):
            NativeAppDetailView(target: target)
        case .search:
            NativeSearchView()
        case .submitApp:
            SubmitAppView()
        case .tutorial:
            TutorialComponent()
        case .developer:
            NativeDeveloperView()
        case .friends:
            FriendPageView { path.append($0) }
        case .web(let payload):
            QueryWeb(payload: payload)
        case .contact:
            ContactComponent()
        case .appLog:
            AppLogPageView()
        case .htmlPage(let payload):
            HTMLPageView(payload: payload)
        }
    }
}

private extension View {
    @ViewBuilder
    func importantNoticeGate(isPresented: Binding<Bool>, accept: @escaping () -> Void) -> some View {
#if os(macOS)
        sheet(isPresented: isPresented) {
            ImportantNoticeGate(accept: accept)
                .frame(minWidth: 620, minHeight: 640)
        }
#else
        fullScreenCover(isPresented: isPresented) {
            ImportantNoticeGate(accept: accept)
        }
#endif
    }
}

private struct WebBackupView: View {
    @Environment(\.dashboardVisibility) private var visibility
    @State private var endpoint: SiteEndpoint = .s
    @State private var controller = WebViewController()

    var body: some View {
        ZStack(alignment: .top) {
            dashboardPageBackground.ignoresSafeArea()
            Web(url: endpoint.url, controller: controller)
                .id(endpoint.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            WebLoadingProgressView(controller: controller)
        }
        .navigationTitle("备用网页")
        .toolbar {
            ToolbarItem(placement: leadingPlacement) {
                Button("返回", systemImage: "chevron.backward") { controller.goBack() }
                    .disabled(!controller.canGoBack)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("站点", selection: $endpoint) {
                    Text(SiteEndpoint.s.title).tag(SiteEndpoint.s)
                    if visibility.showTSite {
                        Text(SiteEndpoint.t.title).tag(SiteEndpoint.t)
                    }
                }
                .pickerStyle(.menu)
                Button("刷新", systemImage: "arrow.clockwise") { controller.reload() }
                ShareLink(item: endpoint.url)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("备用网页仅用于原生接口不可用时访问站点，日常功能请使用首页、应用和搜索。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
        }
        .onChange(of: visibility.showTSite) {
            if !visibility.showTSite, endpoint == .t { endpoint = .s }
        }
    }

    private var leadingPlacement: ToolbarItemPlacement {
#if os(macOS)
        .navigation
#else
        .topBarLeading
#endif
    }
}

private struct ImportantNoticeGate: View {
    let accept: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Label("重要提示", systemImage: "exclamationmark.triangle.fill")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.red)
                    DashboardCard {
                        WarningTextContent()
                    }
                    Button("我已阅读并同意", action: accept)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    Text("同意后应用才会加载市场数据。可随后在“我的”中重新查看重要提示和隐私政策。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .dashboardPage()
        }
        .interactiveDismissDisabled()
    }
}
