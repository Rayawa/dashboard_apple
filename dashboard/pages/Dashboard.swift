import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable, Hashable {
    case sStation
    case home
    case apps
    case profile

    var id: String { rawValue }

    static let mainPages: [DashboardSection] = [.sStation, .home, .apps, .profile]

    var title: String {
        switch self {
        case .sStation: "S站"
        case .home: "首页"
        case .apps: "应用"
        case .profile: "我的"
        }
    }

    var symbol: String {
        switch self {
        case .sStation: "wifi.router.fill"
        case .home: "house"
        case .apps: "square.grid.2x2"
        case .profile: "person.crop.circle"
        }
    }

}

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var path: [AppRoute] = []
    @State private var selectedSection: DashboardSection? = .home
    @State private var compactColumn: NavigationSplitViewColumn = .detail
    @State private var splitVisibility: NavigationSplitViewVisibility = .automatic
    @State private var availableWidth: CGFloat = 1_000
    @State private var visibility = DashboardVisibilityConfig.restricted
    @AppStorage("accepted_important_notice_v3") private var acceptedNotice = false

    var body: some View {
        NavigationSplitView(columnVisibility: $splitVisibility, preferredCompactColumn: $compactColumn) {
            List(selection: sectionSelection) {
                ForEach(DashboardSection.mainPages) { section in
                    NavigationLink(value: section) {
                        Label(section.title, systemImage: section.symbol)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Dashboard")
            .frame(minWidth: 150)
        } detail: {
            NavigationStack(path: $path) {
                Group {
                    if acceptedNotice {
                        sectionContent(selectedSection ?? .home)
                    } else {
                        dashboardPageBackground.ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    if acceptedNotice, showsFloatingNavigation {
                        FloatingDashboardNavigation(selection: sectionSelection)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 6)
                    }
                }
                .navigationDestination(for: AppRoute.self, destination: destination)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            availableWidth = width
        }
        .environment(\.dashboardVisibility, visibility)
        .task(id: acceptedNotice) {
            guard acceptedNotice else { return }
            visibility = await AppAPIService.dashboardConfig()
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
        selectedSection = .apps
        compactColumn = .detail
        path = [.appDetail(target)]
    }

    private var sectionSelection: Binding<DashboardSection?> {
        Binding(
            get: { selectedSection },
            set: { newValue in
                guard newValue != selectedSection else { return }
                path.removeAll()
                selectedSection = newValue
                compactColumn = .detail
                DashboardFeedback.selection()
            }
        )
    }

    private var showsFloatingNavigation: Bool {
        horizontalSizeClass == .compact || splitVisibility == .detailOnly || availableWidth < 680
    }

    @ViewBuilder
    private func sectionContent(_ section: DashboardSection) -> some View {
        switch section {
        case .sStation: SStationView()
        case .home: HomeDashboardView()
        case .apps: MarketAppsView()
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

private struct FloatingDashboardNavigation: View {
    @Binding var selection: DashboardSection?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DashboardSection.mainPages) { section in
                Button {
                    selection = section
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: section.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .symbolVariant(selection == section ? .fill : .none)
                        Text(section.title)
                            .font(.caption2.weight(selection == section ? .semibold : .regular))
                    }
                    .foregroundStyle(selection == section ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background {
                        if selection == section {
                            Capsule().fill(Color.accentColor.opacity(0.13))
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(section.title)
                .accessibilityAddTraits(selection == section ? .isSelected : [])
            }
        }
        .padding(5)
        .frame(maxWidth: 460)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(.primary.opacity(0.1), lineWidth: 0.5) }
        .shadow(color: .black.opacity(0.14), radius: 12, y: 5)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("主导航")
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

private struct SStationView: View {
    @State private var controller = WebViewController()

    var body: some View {
        ZStack(alignment: .top) {
            dashboardPageBackground.ignoresSafeArea()
            Web(url: DashboardURLs.sBase, controller: controller)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            WebLoadingProgressView(controller: controller)
        }
        .navigationTitle("S站")
        .toolbar {
            ToolbarItem(placement: leadingPlacement) {
                Button("返回", systemImage: "chevron.backward") { controller.goBack() }
                    .disabled(!controller.canGoBack)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button("刷新", systemImage: "arrow.clockwise") { controller.reload() }
                ShareLink(item: DashboardURLs.sBase)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("S站内容由 Dashboard 项目网站提供；应用数据浏览与搜索请使用原生“首页”和“应用”页面。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
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
