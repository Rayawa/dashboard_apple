import SwiftUI

struct MarketAppsView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case overview = "概况"
        case list = "总表"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .overview

    var body: some View {
        Group {
            switch mode {
            case .overview: MarketOverviewChartsView()
            case .list: NativeAppListView()
            }
        }
        .navigationTitle("应用")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("页面", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            }
        }
    }
}

private struct NativeAppListView: View {
    @Environment(\.dashboardVisibility) private var visibility
    private enum AppType: String, CaseIterable, Identifiable {
        case all = "全部类型"
        case app = "应用"
        case atomic = "元服务"
        var id: String { rawValue }
    }

    private enum FilterField: String, CaseIterable, Identifiable {
        case name = "应用名称"
        case kindName = "分类"
        case kindTypeName = "类型"
        case tagName = "标签"
        case developerName = "开发者"

        var id: String { rawValue }
        var key: String {
            switch self {
            case .name: "name"
            case .kindName: "kind_name"
            case .kindTypeName: "kind_type_name"
            case .tagName: "tag_name"
            case .developerName: "developer_name"
            }
        }
    }

    private enum SortField: String, CaseIterable, Identifiable {
        case updatedAt = "更新时间"
        case downloadCount = "下载量"
        case ratingCount = "评分数量"
        case size = "应用大小"
        case listedAt = "上架时间"

        var id: String { rawValue }
        var key: String {
            switch self {
            case .updatedAt: "updated_at"
            case .downloadCount: "download_count"
            case .ratingCount: "total_star_rating_count"
            case .size: "size_bytes"
            case .listedAt: "listed_at"
            }
        }
    }

    @State private var apps: [MarketApp] = []
    @State private var page = 1
    @State private var total = 0
    @State private var totalPages = 1
    @State private var jumpText = ""
    @State private var pageSize = 20
    @State private var appType: AppType = .all
    @State private var filterField: FilterField = .name
    @State private var filterText = ""
    @State private var appliedFilter = ""
    @State private var sortField: SortField = .updatedAt
    @State private var descending = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var staleDate: Date?
    @State private var requestID = UUID()
    @State private var advancedExpanded = false
    @State private var advancedExpression: SearchExpression?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                filters

                HStack {
                    Text("共 \(DashboardFormat.count(total)) 条应用数据")
                        .font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    if let staleDate { OfflineCacheBanner(cachedAt: staleDate) }
                }

                if isLoading, apps.isEmpty {
                    LoadingStateView(text: "正在加载应用列表…")
                } else if let errorMessage, apps.isEmpty {
                    ErrorStateView(message: errorMessage) { reload(force: true) }
                } else if apps.isEmpty {
                    ContentUnavailableView("没有匹配的应用", systemImage: "magnifyingglass")
                } else {
                    ForEach(apps) { app in
                        NavigationLink(value: AppRoute.appDetail(.init(appId: app.appId, packageName: app.pkgName, preview: app))) {
                            NativeAppRow(app: app)
                        }
                        .buttonStyle(.plain)
                    }
                    pagination
                }
            }
            .padding()
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .refreshable { await load(force: true) }
        .task {
            if apps.isEmpty { await load(force: false) }
        }
    }

    private var filters: some View {
        DashboardCard {
            VStack(spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { filterControls }
                    VStack(spacing: 10) { filterControls }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { sortControls }
                    VStack(spacing: 10) { sortControls }
                }
                DisclosureGroup("高级组合搜索", isExpanded: $advancedExpanded) {
                    AdvancedSearchPanel(
                        isActive: advancedExpression != nil,
                        allowsDownloadMetrics: visibility.showAppDownloadMetrics,
                        onApply: { expression in
                            advancedExpression = expression
                            appType = .all
                            filterText = ""
                            appliedFilter = ""
                            reloadFromFirstPage()
                        },
                        onClear: {
                            advancedExpression = nil
                            reloadFromFirstPage()
                        }
                    )
                    .padding(.top, 10)
                }
            }
        }
    }

    @ViewBuilder
    private var filterControls: some View {
        Picker("类型", selection: Binding(
            get: { appType },
            set: { newValue in
                appType = newValue
                advancedExpression = nil
                reloadFromFirstPage()
            }
        )) {
            ForEach(AppType.allCases) { Text($0.rawValue).tag($0) }
        }
        .frame(minWidth: 130)
        Picker("筛选字段", selection: $filterField) {
            ForEach(FilterField.allCases) { Text($0.rawValue).tag($0) }
        }
        .frame(minWidth: 130)
        TextField("输入筛选内容", text: $filterText)
            .textFieldStyle(.roundedBorder)
            .onSubmit(applyFilter)
        Button("筛选", systemImage: "line.3.horizontal.decrease.circle", action: applyFilter)
            .buttonStyle(.borderedProminent)
        Button("清除", systemImage: "xmark") {
            filterText = ""
            appliedFilter = ""
            appType = .all
            advancedExpression = nil
            page = 1
            reload()
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var sortControls: some View {
        Picker("排序", selection: $sortField) {
            ForEach(sortOptions) { Text($0.rawValue).tag($0) }
        }
        .onChange(of: sortField) { reloadFromFirstPage() }
        Picker("每页", selection: $pageSize) {
            Text("每页 20 条").tag(20)
            Text("每页 50 条").tag(50)
            Text("每页 100 条").tag(100)
        }
        .onChange(of: pageSize) { reloadFromFirstPage() }
        Button(descending ? "降序" : "升序", systemImage: descending ? "arrow.down" : "arrow.up") {
            descending.toggle()
            reloadFromFirstPage()
        }
        .buttonStyle(.bordered)
        Spacer(minLength: 0)
    }

    private var pagination: some View {
        ViewThatFits(in: .horizontal) {
            HStack { widePaginationControls }
            VStack(spacing: 10) {
                HStack {
                    previousPageButton
                    Spacer()
                    pageIndicator
                    Spacer()
                    nextPageButton
                }
                HStack {
                    Spacer()
                    jumpControls
                }
            }
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var widePaginationControls: some View {
        previousPageButton
        Spacer()
        pageIndicator
        Spacer()
        nextPageButton
        jumpControls
    }

    private var previousPageButton: some View {
        Button("上一页", systemImage: "chevron.left") {
            page -= 1
            reload()
        }
        .disabled(page <= 1 || isLoading)
    }

    private var nextPageButton: some View {
        Button("下一页", systemImage: "chevron.right") {
            page += 1
            reload()
        }
        .labelStyle(.titleAndIcon)
        .disabled(page >= totalPages || isLoading)
    }

    private var pageIndicator: some View {
        Text("第 \(page) / \(totalPages) 页")
            .font(.callout.monospacedDigit())
    }

    @ViewBuilder
    private var jumpControls: some View {
        TextField("页码", text: $jumpText)
            .textFieldStyle(.roundedBorder)
            .frame(width: 76)
            .onSubmit(jumpToPage)
            .accessibilityLabel("输入要跳转的页码")
        Button("跳转", action: jumpToPage)
            .disabled(jumpPage == nil || isLoading)
    }

    private var jumpPage: Int? {
        guard let value = Int(jumpText), (1...totalPages).contains(value) else { return nil }
        return value
    }

    private var sortOptions: [SortField] {
        SortField.allCases.filter { $0 != .downloadCount || visibility.showAppDownloadMetrics }
    }

    private func jumpToPage() {
        guard let jumpPage else { return }
        page = jumpPage
        reload()
    }

    private func applyFilter() {
        appliedFilter = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        advancedExpression = nil
        reloadFromFirstPage()
    }

    private func reloadFromFirstPage() {
        page = 1
        reload()
    }

    private func reload(force: Bool = false) {
        Task { await load(force: force) }
    }

    @MainActor
    private func load(force: Bool) async {
        let id = UUID()
        requestID = id
        isLoading = true
        errorMessage = nil

        var searchKey: String?
        var searchValue: String?
        let excludeAtomic = appType == .app
        if appType == .atomic {
            searchKey = "pkg_name"
            searchValue = "com.atomicservice"
        } else if !appliedFilter.isEmpty {
            searchKey = filterField.key
            searchValue = appliedFilter
        }

        do {
            let query = AppsPageQuery(
                page: page,
                pageSize: pageSize,
                sort: sortField.key,
                descending: descending,
                searchKey: searchKey,
                searchValue: searchValue,
                exact: false,
                excludeHuawei: false,
                excludeAtomic: excludeAtomic
            )
            let result: APIDataResult<APIEnvelope<PageInfo<MarketApp>>>
            if let advancedExpression {
                result = try await AppAPIService.appsQuery(query, expression: advancedExpression, force: force)
            } else {
                result = try await AppAPIService.appsPage(query, force: force)
            }
            guard requestID == id else { return }
            apps = result.data.data.data
            total = result.data.data.totalCount
            totalPages = max(1, result.data.data.totalPages)
            staleDate = result.isStale ? result.cachedAt : nil
        } catch {
            guard requestID == id else { return }
            errorMessage = error.localizedDescription
        }
        if requestID == id { isLoading = false }
    }
}

private struct NativeAppRow: View {
    @Environment(\.dashboardVisibility) private var visibility
    let app: MarketApp

    var body: some View {
        DashboardCard {
            HStack(spacing: 14) {
                AppIconView(app: app, size: 58)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(app.name).font(.headline).lineLimit(1)
                        if app.pkgName.hasPrefix("com.atomicservice") {
                            Text("元服务").font(.caption2.bold()).foregroundStyle(.mint)
                        }
                    }
                    Text(app.developerName).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 14) { metadata }
                        VStack(alignment: .leading, spacing: 2) { metadata }
                    }
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private var metadata: some View {
        if visibility.showAppDownloadMetrics {
            Label(DashboardFormat.count(app.downloadCount), systemImage: "arrow.down.circle")
        }
        Label(app.displayRating.map { String(format: "%.1f", $0) } ?? "-", systemImage: "star")
        Label(DashboardFormat.bytes(app.sizeBytes), systemImage: "internaldrive")
        Text(app.kindName)
    }

    private var accessibilitySummary: String {
        let base = "\(app.name)，开发者 \(app.developerName)"
        return visibility.showAppDownloadMetrics ? "\(base)，下载量 \(app.downloadCount)" : base
    }
}
