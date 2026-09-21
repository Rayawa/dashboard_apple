import Charts
import SwiftUI

struct MarketOverviewChartsView: View {
    @Environment(\.dashboardVisibility) private var visibility
    @State private var rating: RatingDistribution?
    @State private var minimumSDK: [SDKDistributionPoint] = []
    @State private var targetSDK: [SDKDistributionPoint] = []
    @State private var apiHistory: [APIHistorySnapshot] = []
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var errorMessage: String?
    @State private var staleDate: Date?
    @State private var selectedMinimumSDK: Int?
    @State private var selectedTargetSDK: Int?
    @State private var selectedRatingAngle: Double?
    @State private var selectedHistoryDate: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let staleDate { OfflineCacheBanner(cachedAt: staleDate) }
                if isLoading, !hasLoaded {
                    LoadingStateView(text: "正在加载市场图表…")
                } else if let errorMessage, !hasChartData {
                    ErrorStateView(message: errorMessage) {
                        Task { await load(force: true) }
                    }
                } else {
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                    if visibility.showTotalDownloadRanking || visibility.showNonHuaweiDownloadRanking {
                        DownloadLeaderboardsView()
                    }
                    if visibility.showTotalDownloadRanking, visibility.showDownloadHistory {
                        DownloadGrowthView()
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
                        if !targetSDK.isEmpty {
                            sdkChart(title: "目标 SDK 分布", points: targetSDK, selection: $selectedTargetSDK, tint: .blue)
                        }
                        if !minimumSDK.isEmpty {
                            sdkChart(title: "最低 SDK 分布", points: minimumSDK, selection: $selectedMinimumSDK, tint: .mint)
                        }
                        if let rating {
                            ratingChart(rating)
                        }
                    }
                    if !apiHistory.isEmpty {
                        apiHistoryChart
                    }
                }
            }
            .padding()
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .refreshable { await load(force: true) }
        .task {
            if !hasLoaded { await load(force: false) }
        }
    }

    private var hasChartData: Bool {
        rating != nil || !minimumSDK.isEmpty || !targetSDK.isEmpty || !apiHistory.isEmpty
    }

    private var apiHistoryChart: some View {
        let latestSDKs = Array(Set(apiHistory.flatMap { $0.percentages.keys.compactMap(Int.init) }))
            .sorted(by: >)
            .prefix(6)
        let series = apiHistory.flatMap { snapshot in
            latestSDKs.compactMap { sdk -> APIHistorySeriesPoint? in
                guard let value = snapshot.percentages[String(sdk)],
                      let date = parseHistoryDate(snapshot.date) else { return nil }
                return APIHistorySeriesPoint(date: date, sdk: sdk, percentage: value)
            }
        }
        let selectedPoints = selectedHistoryPoints(in: series)
        return DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("API 版本占比历史").font(.headline)
                if selectedPoints.isEmpty {
                    Text("拖动选点查看占比；图表可横向滚动")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    let date = selectedPoints[0].date.formatted(date: .abbreviated, time: .omitted)
                    Text("\(date) · " + selectedPoints.map {
                        "API \($0.sdk) \($0.percentage.formatted(.number.precision(.fractionLength(1))))%"
                    }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(2)
                }
                Chart {
                    ForEach(series) { point in
                        LineMark(
                            x: .value("日期", point.date),
                            y: .value("占比", point.percentage),
                            series: .value("API", "API \(point.sdk)")
                        )
                        .foregroundStyle(by: .value("API", "API \(point.sdk)"))
                        .interpolationMethod(.catmullRom)
                    }
                    if let date = selectedPoints.first?.date {
                        RuleMark(x: .value("选中日期", date))
                            .foregroundStyle(.secondary.opacity(0.55))
                            .lineStyle(.init(lineWidth: 1, dash: [4]))
                    }
                }
                .chartXSelection(value: $selectedHistoryDate)
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: 120 * 24 * 60 * 60)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text("\(number.formatted(.number.precision(.fractionLength(0))))%")
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(minHeight: 310)
                .accessibilityLabel("API 版本占比历史折线图")
            }
        }
    }

    private func parseHistoryDate(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }

    private func selectedHistoryPoints(in series: [APIHistorySeriesPoint]) -> [APIHistorySeriesPoint] {
        guard let selectedHistoryDate,
              let date = series.map(\.date).min(by: {
                  abs($0.timeIntervalSince(selectedHistoryDate)) < abs($1.timeIntervalSince(selectedHistoryDate))
              }) else { return [] }
        return series.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.sdk > $1.sdk }
    }

    private func sdkChart(
        title: String,
        points: [SDKDistributionPoint],
        selection: Binding<Int?>,
        tint: Color
    ) -> some View {
        let visible = Array(points.sorted { $0.sdk < $1.sdk }.suffix(18))
        return DashboardCard(tint: tint) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.headline)
                if let selected = selection.wrappedValue,
                   let point = visible.first(where: { $0.sdk == selected }) {
                    Text("API \(point.sdk)：\(DashboardFormat.count(point.count)) 款")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("点按或拖动查看具体数量")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Chart(visible) { point in
                    BarMark(
                        x: .value("SDK", point.sdk),
                        y: .value("应用数", point.count)
                    )
                    .foregroundStyle(point.sdk == selection.wrappedValue ? tint : tint.opacity(0.65))
                    .cornerRadius(3)
                }
                .chartXSelection(value: selection)
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(minHeight: 250)
                .accessibilityLabel(title)
            }
        }
    }

    private func ratingChart(_ distribution: RatingDistribution) -> some View {
        let values = distribution.values
        let selected = selectedRating(in: values)
        return DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("应用评分分布").font(.headline)
                Text(selected.map { "\($0.star) 星：\(DashboardFormat.count($0.count)) 款" } ?? "点按扇区查看具体数量")
                    .font(.caption).foregroundStyle(.secondary)
                Chart(values, id: \.star) { item in
                    SectorMark(
                        angle: .value("应用数", item.count),
                        innerRadius: .ratio(0.56),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("评分", "\(item.star) 星"))
                    .opacity(selected == nil || selected?.star == item.star ? 1 : 0.45)
                }
                .chartAngleSelection(value: $selectedRatingAngle)
                .chartLegend(position: .bottom, alignment: .center, spacing: 10)
                .frame(minHeight: 250)
                .accessibilityLabel("应用评分分布饼图")
            }
        }
    }

    private func selectedRating(in values: [(star: Int, count: Int)]) -> (star: Int, count: Int)? {
        guard let selectedRatingAngle else { return nil }
        var cumulative = 0.0
        for item in values {
            cumulative += Double(item.count)
            if selectedRatingAngle <= cumulative { return item }
        }
        return values.last
    }

    @MainActor
    private func load(force: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        async let ratingRequest = try? AppAPIService.ratingDistribution(force: force)
        async let minimumRequest = try? AppAPIService.sdkDistribution(target: false, force: force)
        async let targetRequest = try? AppAPIService.sdkDistribution(target: true, force: force)
        async let historyRequest = try? AppAPIService.apiHistory(force: force)
        let (ratingResult, minimumResult, targetResult, historyResult) = await (
            ratingRequest, minimumRequest, targetRequest, historyRequest
        )

        if let ratingResult {
            rating = ratingResult.data.data
        }
        if let minimumResult {
            minimumSDK = minimumResult.data.data
        }
        if let targetResult {
            targetSDK = targetResult.data.data
        }
        if let historyResult {
            apiHistory = historyResult.data.data
        }
        let staleResults: [(Bool, Date?)] = [
            (ratingResult?.isStale == true, ratingResult?.cachedAt),
            (minimumResult?.isStale == true, minimumResult?.cachedAt),
            (targetResult?.isStale == true, targetResult?.cachedAt),
            (historyResult?.isStale == true, historyResult?.cachedAt),
        ]
        staleDate = staleResults.compactMap { $0.0 ? $0.1 : nil }.min()
        let failureCount = [ratingResult == nil, minimumResult == nil, targetResult == nil, historyResult == nil]
            .filter { $0 }.count
        if failureCount > 0 {
            errorMessage = failureCount == 4 ? "市场图表暂时不可用" : "有 \(failureCount) 项图表数据加载失败，其余内容仍可使用"
        }
        hasLoaded = true
    }
}

private struct APIHistorySeriesPoint: Identifiable {
    let date: Date
    let sdk: Int
    let percentage: Double
    var id: String { "\(sdk)-\(date.timeIntervalSince1970)" }
}
