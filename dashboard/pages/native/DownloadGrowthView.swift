import SwiftUI

struct DownloadLeaderboardsView: View {
    @Environment(\.dashboardVisibility) private var visibility

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
            if visibility.showTotalDownloadRanking {
                DownloadLeaderboardView(title: "总下载榜", excludeHuawei: false)
            }
            if visibility.showNonHuaweiDownloadRanking {
                DownloadLeaderboardView(title: "非华为应用下载榜", excludeHuawei: true)
            }
        }
    }
}

private struct DownloadLeaderboardView: View {
    let title: String
    let excludeHuawei: Bool

    @State private var apps: [MarketApp] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var staleDate: Date?

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Button("刷新", systemImage: "arrow.clockwise") {
                        Task { await load(force: true) }
                    }
                    .labelStyle(.iconOnly)
                    .disabled(isLoading)
                }
                if let staleDate { OfflineCacheBanner(cachedAt: staleDate) }
                if let errorMessage, !apps.isEmpty {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote).foregroundStyle(.orange)
                }
                if isLoading, apps.isEmpty {
                    LoadingStateView(text: "正在加载排名…")
                } else if let errorMessage, apps.isEmpty {
                    ErrorStateView(message: errorMessage) {
                        Task { await load(force: true) }
                    }
                } else if apps.isEmpty {
                    ContentUnavailableView("暂无排名数据", systemImage: "list.number")
                } else {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        NavigationLink(value: AppRoute.appDetail(.init(
                            appId: app.appId,
                            packageName: app.pkgName,
                            preview: app
                        ))) {
                            HStack(spacing: 9) {
                                Text("\(index + 1)")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(.tint)
                                    .frame(width: 24)
                                AppIconView(app: app, size: 34)
                                Text(app.name).font(.callout.weight(.semibold)).lineLimit(1)
                                Spacer(minLength: 6)
                                Text(DashboardFormat.count(app.downloadCount))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.orange)
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("第 \(index + 1) 名，\(app.name)，下载量 \(app.downloadCount)")
                        if index < apps.count - 1 { Divider() }
                    }
                }
            }
        }
        .task { await load(force: false) }
    }

    @MainActor
    private func load(force: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await AppAPIService.appsPage(.init(
                page: 1,
                pageSize: 10,
                sort: "download_count",
                descending: true,
                excludeHuawei: excludeHuawei
            ), force: force)
            apps = result.data.data.data.stableUniqued(by: \MarketApp.id)
            staleDate = result.isStale ? result.cachedAt : nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct DownloadGrowthView: View {
    @State private var period = 1
    @State private var apps: [DownloadGrowthApp] = []
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var staleDate: Date?
    @State private var requestID = UUID()

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 14) { headerContent }
                    VStack(alignment: .leading, spacing: 10) { headerContent }
                }

                if let staleDate { OfflineCacheBanner(cachedAt: staleDate) }
                if let errorMessage, !apps.isEmpty {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote).foregroundStyle(.orange)
                }

                if isLoading, !hasLoaded {
                    LoadingStateView(text: "正在加载下载增长榜…")
                } else if let errorMessage, apps.isEmpty {
                    ErrorStateView(message: errorMessage) {
                        Task { await load(force: true) }
                    }
                } else if apps.isEmpty {
                    ContentUnavailableView(
                        "当前周期暂无数据",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("对应日期快照生成后会自动显示。")
                    )
                } else {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        NavigationLink(value: AppRoute.appDetail(.init(appId: app.appId, packageName: app.pkgName))) {
                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.callout.bold().monospacedDigit())
                                    .foregroundStyle(.tint)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(app.name).font(.callout.weight(.semibold)).lineLimit(1)
                                    Text("\(DashboardFormat.dateTime(app.priorPeriodDate)) → \(DashboardFormat.dateTime(app.currentPeriodDate))")
                                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer(minLength: 8)
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("+\(DashboardFormat.count(app.downloadIncrement))")
                                        .font(.callout.bold().monospacedDigit())
                                        .foregroundStyle(.green)
                                    Text("当前 \(DashboardFormat.count(app.currentDownloadCount))")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("第 \(index + 1) 名，\(app.name)，下载增长 \(app.downloadIncrement)")
                        if index < apps.count - 1 { Divider() }
                    }
                }
            }
        }
        .task(id: period) {
            apps = []
            hasLoaded = false
            staleDate = nil
            await load(force: false)
        }
    }

    @ViewBuilder
    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("下载增长榜").font(.headline)
            Text("按快照周期对比下载量增量").font(.caption).foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
        Picker("周期", selection: $period) {
            Text("近 1 天").tag(1)
            Text("近 7 天").tag(7)
            Text("近 30 天").tag(30)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 320)
    }

    @MainActor
    private func load(force: Bool) async {
        let id = UUID()
        requestID = id
        isLoading = true
        errorMessage = nil
        do {
            let result = try await AppAPIService.downloadGrowth(days: period, force: force)
            guard requestID == id else { return }
            apps = result.data.data.stableUniqued(by: \DownloadGrowthApp.id)
            staleDate = result.isStale ? result.cachedAt : nil
            hasLoaded = true
        } catch {
            guard requestID == id else { return }
            errorMessage = error.localizedDescription
        }
        if requestID == id { isLoading = false }
    }
}
