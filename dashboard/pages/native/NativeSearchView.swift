import SwiftUI

struct NativeSearchView: View {
    @State private var query = ""
    @State private var results: [MarketApp] = []
    @State private var recommendations: [MarketApp] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var statusMessage = "输入应用名称、包名、App ID 或应用市场链接"
    @State private var staleDate: Date?
    @State private var requestID = UUID()
    @AppStorage("search_history") private var storedHistory = ""
    @AppStorage("username") private var username = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                searchCard

                if isSearching || errorMessage != nil || !results.isEmpty {
                    HStack(spacing: 8) {
                        if isSearching { ProgressView().controlSize(.small) }
                        Text(errorMessage ?? statusMessage)
                            .font(.footnote)
                            .foregroundStyle(errorMessage == nil ? Color.secondary : Color.red)
                        Spacer()
                        if let staleDate { OfflineCacheBanner(cachedAt: staleDate) }
                    }
                }

                if !results.isEmpty {
                    Text("搜索结果（\(results.count)）").font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], spacing: 12) {
                        ForEach(results) { app in
                            NavigationLink(value: AppRoute.appDetail(.init(
                                appId: app.appId,
                                packageName: app.pkgName,
                                preview: app
                            ))) {
                                NativeSearchResultRow(app: app)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else if !isSearching {
                    historySection
                    recommendationSection
                    if history.isEmpty, recommendations.isEmpty, errorMessage == nil {
                        ContentUnavailableView(
                            "搜索应用",
                            systemImage: "text.magnifyingglass",
                            description: Text("输入名称、包名、App ID 或应用市场链接开始查询。")
                        )
                    }
                }
            }
            .padding()
            .frame(maxWidth: 1050)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .navigationTitle("搜索")
        .task {
            if recommendations.isEmpty { await loadRecommendations() }
        }
    }

    private var searchCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("查找或收录应用", systemImage: "magnifyingglass")
                    .font(.title2.bold())
                Text("支持应用名称、包名、App ID，以及华为应用市场或看板链接。未收录的包名和 App ID 会自动尝试投稿。")
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    TextField("输入应用信息", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(search)
                    Button("搜索", action: search)
                        .buttonStyle(.borderedProminent)
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                }
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        if !history.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("搜索历史").font(.title2.bold())
                    Spacer()
                    Button("删除全部", systemImage: "trash", role: .destructive) {
                        storedHistory = ""
                    }
                }
                FlowLayout(spacing: 8) {
                    ForEach(history, id: \.self) { item in
                        Button(item) {
                            query = item
                            search()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recommendationSection: some View {
        if !recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("搜索推荐").font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                    ForEach(recommendations) { app in
                        NavigationLink(value: AppRoute.appDetail(.init(
                            appId: app.appId,
                            packageName: app.pkgName,
                            preview: app
                        ))) {
                            DashboardCard {
                                HStack(spacing: 10) {
                                    AppIconView(app: app, size: 44)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(app.name).font(.callout.bold()).lineLimit(1)
                                        Text(app.developerName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var history: [String] {
        storedHistory.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }

    private func search() {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !isSearching else { return }
        guard value.count <= 512 else {
            errorMessage = "搜索内容不能超过 512 个字符"
            statusMessage = "请缩短搜索内容后重试"
            return
        }
        DashboardFeedback.selection()
        Task { await performSearch(value) }
    }

    @MainActor
    private func performSearch(_ value: String) async {
        let id = UUID()
        requestID = id
        isSearching = true
        errorMessage = nil
        staleDate = nil
        results = []
        statusMessage = "正在查找应用…"
        recordHistory(value)

        do {
            if let target = directTarget(from: value) {
                let detail = try await loadOrSubmit(target)
                guard requestID == id else { return }
                results = [detail.app]
                staleDate = detail.staleDate
                statusMessage = detail.wasSubmitted ? "新应用已完成收录" : (detail.staleDate == nil ? "搜索结果已完整加载" : "已从离线缓存加载结果")
            } else {
                let searchResult = try await findAllByName(value, requestID: id)
                guard requestID == id else { return }
                results = searchResult.apps
                staleDate = searchResult.staleDate
                statusMessage = searchResult.staleDate == nil ? "已加载全部 \(results.count) 个结果" : "已从缓存加载 \(results.count) 个结果"
            }
            if results.isEmpty {
                throw APIError.notFound("未找到同名应用；如需投稿，请输入包名、App ID 或应用市场链接")
            }
        } catch {
            guard requestID == id else { return }
            errorMessage = error.localizedDescription
            statusMessage = "搜索或投稿未完成"
        }
        if requestID == id { isSearching = false }
    }

    private func loadOrSubmit(_ target: AppDetailTarget) async throws -> DirectSearchResult {
        do {
            let result: APIDataResult<APIEnvelope<AppDetailPayload>>
            if let appId = target.appId {
                result = try await AppAPIService.appDetail(appId: appId)
            } else if let packageName = target.packageName {
                result = try await AppAPIService.appDetail(packageName: packageName)
            } else {
                throw APIError.invalidInput("缺少应用标识")
            }
            if result.data.data.newApp {
                return try await submit(target)
            }
            return DirectSearchResult(
                app: result.data.data.fullInfo,
                staleDate: result.isStale ? result.cachedAt : nil,
                wasSubmitted: false
            )
        } catch APIError.notFound {
            return try await submit(target)
        }
    }

    private func submit(_ target: AppDetailTarget) async throws -> DirectSearchResult {
        let response = try await AppAPIService.submitApp(
            packageName: target.packageName ?? "",
            appId: target.appId ?? "",
            remark: username
        )
        return DirectSearchResult(app: response.data.fullInfo, staleDate: nil, wasSubmitted: true)
    }

    private func findAllByName(_ name: String, requestID id: UUID) async throws -> NameSearchResult {
        let first = try await AppAPIService.appsPage(.init(
            page: 1,
            pageSize: 100,
            sort: "download_count",
            descending: true,
            searchKey: "name",
            searchValue: name,
            exact: false
        ), force: true)
        var apps = first.data.data.data
        var stale = first.isStale
        var cachedAt = first.cachedAt
        let totalPages = first.data.data.totalPages

        if totalPages > 1 {
            for page in 2...totalPages {
                try Task.checkCancellation()
                guard requestID == id else { throw CancellationError() }
                let next = try await AppAPIService.appsPage(.init(
                    page: page,
                    pageSize: 100,
                    sort: "download_count",
                    descending: true,
                    searchKey: "name",
                    searchValue: name,
                    exact: false
                ), force: true)
                apps.append(contentsOf: next.data.data.data)
                if next.isStale {
                    stale = true
                    cachedAt = cachedAt ?? next.cachedAt
                }
            }
        }

        apps.sort { relevance($0, query: name) < relevance($1, query: name) }
        return NameSearchResult(apps: apps, staleDate: stale ? cachedAt : nil)
    }

    private func relevance(_ app: MarketApp, query: String) -> Int {
        let needle = query.lowercased()
        let name = app.name.lowercased()
        let package = app.pkgName.lowercased()
        if name == needle || package == needle { return 0 }
        if name.hasPrefix(needle) { return 1 }
        if package.hasPrefix(needle) { return 2 }
        if name.contains(needle) { return 3 }
        if package.contains(needle) { return 4 }
        return 5
    }

    private func directTarget(from value: String) -> AppDetailTarget? {
        DashboardInputParser.target(from: value)
    }

    private func recordHistory(_ value: String) {
        let safeValue = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespaces)
        guard !safeValue.isEmpty else { return }
        var values = history.filter { $0 != safeValue }
        values.insert(safeValue, at: 0)
        storedHistory = values.prefix(10).joined(separator: "\n")
    }

    @MainActor
    private func loadRecommendations() async {
        guard let result = try? await AppAPIService.appsPage(.init(
            page: 1,
            pageSize: 8,
            sort: "download_count",
            descending: true
        )) else { return }
        recommendations = result.data.data.data
    }
}

private struct DirectSearchResult {
    let app: MarketApp
    let staleDate: Date?
    let wasSubmitted: Bool
}

private struct NameSearchResult {
    let apps: [MarketApp]
    let staleDate: Date?
}

private struct NativeSearchResultRow: View {
    @Environment(\.dashboardVisibility) private var visibility
    let app: MarketApp

    var body: some View {
        DashboardCard {
            HStack(spacing: 14) {
                AppIconView(app: app, size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name).font(.headline).lineLimit(1)
                    Text(app.developerName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Text(app.pkgName).font(.caption2).foregroundStyle(.tertiary).lineLimit(1).textSelection(.enabled)
                    HStack(spacing: 8) {
                        if visibility.showAppDownloadMetrics {
                            Text("\(DashboardFormat.count(app.downloadCount)) 下载")
                        }
                        Text("更新：\(DashboardFormat.dateTime(app.updatedAt))")
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 5)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
