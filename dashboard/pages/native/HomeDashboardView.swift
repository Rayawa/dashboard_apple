import SwiftUI

struct HomeDashboardView: View {
    @Environment(\.dashboardVisibility) private var visibility
    @AppStorage("username") private var username = ""
    @State private var market: MarketInfo?
    @State private var recentApps: [MarketApp] = []
    @State private var dailyMaxApps: [DailyMaxDownloadApp] = []
    @State private var developers: [DeveloperRankingEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var partialMessage: String?
    @State private var staleDate: Date?
    @State private var marketUpdatedAt = ""
    @State private var marketObservedAt = Date()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                greeting

                if let staleDate {
                    OfflineCacheBanner(cachedAt: staleDate)
                }
                if let partialMessage, market != nil {
                    Label(partialMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                if isLoading, market == nil {
                    LoadingStateView(text: "正在获取最新市场状态…")
                } else if let errorMessage, market == nil {
                    ErrorStateView(message: errorMessage) {
                        Task { await load(force: true) }
                    }
                } else if let market {
                    overview(market)
                    SyncStatusView(info: market, lastUpdated: marketUpdatedAt, observedAt: marketObservedAt)
                    rankings
                    recent
                }
            }
            .padding()
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .navigationTitle("首页")
        .refreshable { await load(force: true) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("刷新", systemImage: "arrow.clockwise") {
                    Task { await load(force: true) }
                }
                .disabled(isLoading)
            }
        }
        .task {
            if market == nil { await load(force: false) }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.largeTitle.bold())
            Text("欢迎来到 Dashboard 应用看板")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func overview(_ info: MarketInfo) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
            StatCard(title: "应用总数", value: DashboardFormat.count(info.appCount.apps + info.appCount.atomicServices), icon: "square.grid.2x2", tint: .blue)
            StatCard(title: "应用", value: DashboardFormat.count(info.appCount.apps), icon: "app", tint: .cyan)
            StatCard(title: "元服务", value: DashboardFormat.count(info.appCount.atomicServices), icon: "atom", tint: .mint)
            StatCard(title: "开发者", value: DashboardFormat.count(info.developerCount), icon: "person.2", tint: .purple)
            StatCard(title: "专题", value: DashboardFormat.count(info.substanceCount), icon: "rectangle.stack", tint: .orange)
            if visibility.showInstallCount {
                StatCard(title: "鸿蒙装机量", value: DashboardFormat.count(info.appCount.maxDownloadCount), icon: "arrow.down.app", tint: .pink)
            }
        }
    }

    @ViewBuilder
    private var rankings: some View {
        if visibility.showDownloadHistory || !developers.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) { rankingColumns }
                VStack(spacing: 16) { rankingColumns }
            }
        }
    }

    @ViewBuilder
    private var rankingColumns: some View {
        if visibility.showDownloadHistory {
            DashboardCard {
                Text("每日最高下载量应用").font(.headline)
                if dailyMaxApps.isEmpty {
                    Text("暂无每日快照数据")
                        .font(.caption).foregroundStyle(.secondary).padding(.vertical, 10)
                } else {
                    ForEach(Array(dailyMaxApps.prefix(8).enumerated()), id: \.element.id) { index, app in
                        NavigationLink(value: AppRoute.appDetail(.init(appId: app.appId, packageName: app.pkgName))) {
                            HStack {
                                Text("\(index + 1)").monospacedDigit().foregroundStyle(.secondary).frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(app.appName).lineLimit(1)
                                    Text(DashboardFormat.dateTime(app.reportDate))
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(DashboardFormat.count(app.downloadCount))
                                    .font(.caption).foregroundStyle(.orange)
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        if !developers.isEmpty {
            DashboardCard {
                Text("开发者应用数量排行").font(.headline)
                ForEach(Array(developers.prefix(8).enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Text("\(index + 1)").monospacedDigit().foregroundStyle(.secondary).frame(width: 24)
                        Text(item.developerName).lineLimit(1)
                        Spacer()
                        Text("\(item.appCount) 款").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 7)
                }
            }
        }
    }

    @ViewBuilder
    private var recent: some View {
        if !recentApps.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("最近收录").font(.title2.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                    ForEach(recentApps) { app in
                        NavigationLink(value: AppRoute.appDetail(.init(appId: app.appId, packageName: app.pkgName, preview: app))) {
                            DashboardCard {
                                HStack(spacing: 12) {
                                    AppIconView(app: app)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(app.name).font(.headline).lineLimit(1)
                                        Text(app.developerName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        Text("收录于 \(DashboardFormat.dateTime(app.listedAt))")
                                            .font(.caption2).foregroundStyle(.tertiary)
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

    private var greetingText: String {
        let greeting = switch Calendar.current.component(.hour, from: Date()) {
        case 6..<12: "上午好"
        case 12..<18: "下午好"
        default: "晚上好"
        }
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? greeting : "\(greeting)，\(name)"
    }

    @MainActor
    private func load(force: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        partialMessage = nil
        defer { isLoading = false }

        do {
            async let marketRequest = AppAPIService.marketInfo(force: force)
            async let recentRequest = AppAPIService.appsPage(.init(
                page: 1, pageSize: 12, sort: "listed_at", descending: true
            ), force: force)
            async let developerRequest = AppAPIService.developerRanking(force: force)

            let marketResult = try await marketRequest
            market = marketResult.data.data
            marketUpdatedAt = marketResult.data.timestamp ?? ""
            marketObservedAt = Date()
            var staleDates = [marketResult.isStale ? marketResult.cachedAt : nil]
            var failedSupplementalRequests = 0

            if let recentResult = try? await recentRequest {
                recentApps = recentResult.data.data.data
                if recentResult.isStale { staleDates.append(recentResult.cachedAt) }
            } else {
                failedSupplementalRequests += 1
            }
            if visibility.showDownloadHistory {
                if let dailyResult = try? await AppAPIService.dailyMaxDownloads(force: force) {
                    dailyMaxApps = Array(dailyResult.data.data.sorted { $0.reportDate > $1.reportDate }.prefix(10))
                    if dailyResult.isStale { staleDates.append(dailyResult.cachedAt) }
                } else {
                    failedSupplementalRequests += 1
                }
            }
            if let developerResult = try? await developerRequest {
                developers = developerResult.data.data
                if developerResult.isStale { staleDates.append(developerResult.cachedAt) }
            } else {
                failedSupplementalRequests += 1
            }
            staleDate = staleDates.compactMap { $0 }.min()
            if failedSupplementalRequests > 0 {
                partialMessage = "有 \(failedSupplementalRequests) 项首页数据暂时不可用，其余内容仍可使用"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        DashboardCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).foregroundStyle(.secondary)
                    Text(value).font(.system(.title, design: .rounded, weight: .bold)).contentTransition(.numericText())
                }
                Spacer()
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .padding(10)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SyncStatusView: View {
    let info: MarketInfo
    let lastUpdated: String
    let observedAt: Date

    var body: some View {
        DashboardCard {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: info.syncStatus.isSyncingAll ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(info.syncStatus.isSyncingAll ? Color.blue : Color.green)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    content(at: context.date)
                }
            }
        }
    }

    private func content(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("同步信息").font(.headline)
                Spacer()
                Text(info.syncStatus.isSyncingAll ? "全量同步中" : "服务正常")
                    .font(.caption.bold())
                    .foregroundStyle(info.syncStatus.isSyncingAll ? Color.blue : Color.green)
            }
            if let progress = info.syncStatus.progress, progress.count >= 2, progress[1] > 0 {
                ProgressView(value: Double(progress[0]), total: Double(progress[1]))
                Text("进度 \(progress[0]) / \(progress[1])").font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), alignment: .leading)], alignment: .leading, spacing: 5) {
                statusValue("已处理", value: info.syncStatus.totalProcessed)
                statusValue("新增", value: info.syncStatus.totalInserted)
                statusValue("跳过", value: info.syncStatus.totalSkipped)
                statusValue("失败", value: info.syncStatus.totalFailed, isError: info.syncStatus.totalFailed > 0)
                Text("已用时：\(format(info.syncStatus.elapsedTime?.timeInterval))")
                Text("预计总耗时：\(format(info.syncStatus.estimatedTotalTime?.timeInterval))")
            }
            .font(.caption).foregroundStyle(.secondary)
            Text(scheduleText(at: date))
                .font(.caption).foregroundStyle(.primary)
            Divider()
            Text("最后更新：\(DashboardFormat.dateTime(lastUpdated))").font(.caption2).foregroundStyle(.tertiary)
            Text("后端版本：\(info.crateVersion)").font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private func statusValue(_ label: String, value: Int, isError: Bool = false) -> some View {
        Text("\(label)：\(DashboardFormat.count(value))")
            .foregroundStyle(isError ? Color.red : Color.secondary)
    }

    private func format(_ interval: TimeInterval?) -> String {
        interval.map(DashboardFormat.duration) ?? "-"
    }

    private func scheduleText(at date: Date) -> String {
        if info.syncStatus.isSyncingAll {
            guard let elapsed = info.syncStatus.elapsedTime?.timeInterval,
                  let estimated = info.syncStatus.estimatedTotalTime?.timeInterval else {
                return "预计剩余：-"
            }
            return "预计剩余：\(DashboardFormat.duration(max(0, estimated - elapsed)))"
        }
        guard let initial = info.syncStatus.nextSyncCountdown else {
            return "下次同步：等待服务安排"
        }
        let elapsed = Int(date.timeIntervalSince(observedAt))
        return "下次同步：\(DashboardFormat.duration(TimeInterval(max(0, initial - elapsed))))"
    }
}
