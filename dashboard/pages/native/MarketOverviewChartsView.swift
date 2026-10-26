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
    @State private var selectedSDKLabel: String?
    @State private var selectedRatingStar: Int?
    @State private var selectedMinimumSDKAngle: Double?
    @State private var selectedTargetSDKAngle: Double?
    @State private var selectedRatingAngle: Double?
    @State private var sdkExpanded = false
    @State private var availableWidth: CGFloat = 0

    private let chartPalette: [Color] = [
        .blue, .cyan, .green, .orange, .red, .purple, .indigo, .mint,
        .pink, .teal, .yellow, .brown,
    ]

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
                    distributionCharts
                    if !apiHistory.isEmpty {
                        APIHistoryChartCard(history: apiHistory, palette: chartPalette)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            availableWidth = width
        }
        .refreshable { await load(force: true) }
        .task {
            if !hasLoaded { await load(force: false) }
        }
    }

    private var hasChartData: Bool {
        rating != nil || !minimumSDK.isEmpty || !targetSDK.isEmpty || !apiHistory.isEmpty
    }

    @ViewBuilder
    private var distributionCharts: some View {
        if availableWidth >= 840, !targetSDK.isEmpty, !minimumSDK.isEmpty {
            HStack(alignment: .top, spacing: 16) {
                combinedSDKChart
                    .frame(maxWidth: .infinity)
                if let rating {
                    ratingChart(rating)
                        .frame(width: max(280, (availableWidth - 48) / 3))
                }
            }
        } else if availableWidth >= 600, !targetSDK.isEmpty, !minimumSDK.isEmpty {
            combinedSDKChart
            if let rating { ratingChart(rating) }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
                if !targetSDK.isEmpty {
                    sdkChart(title: "目标 SDK 分布", points: targetSDK, angle: $selectedTargetSDKAngle)
                }
                if !minimumSDK.isEmpty {
                    sdkChart(title: "最低 SDK 分布", points: minimumSDK, angle: $selectedMinimumSDKAngle)
                }
                if let rating { ratingChart(rating) }
            }
        }
    }

    private var allSDKLabels: [String] {
        Array(Set(significantSDKLabels(targetSDK) + significantSDKLabels(minimumSDK)))
            .sorted { sdkNumber($0) > sdkNumber($1) }
    }

    private func significantSDKLabels(_ points: [SDKDistributionPoint]) -> [String] {
        let total = max(1, ChartInteractionSupport.nonnegativeSum(points.map(\.count)))
        return points.compactMap { point in
            Double(max(0, point.count)) / Double(total) >= 0.01 ? "API \(point.sdk)" : nil
        }
    }

    private func sdkNumber(_ label: String) -> Int {
        Int(label.replacingOccurrences(of: "API ", with: "")) ?? -1
    }

    private func sdkColor(_ label: String) -> Color {
        guard label != "其他", let index = allSDKLabels.firstIndex(of: label) else { return .secondary }
        return chartPalette[index % chartPalette.count]
    }

    private func firstHiddenSDKLabel(in points: [SDKDistributionPoint]) -> String? {
        significantSDKLabels(points)
            .sorted { sdkNumber($0) > sdkNumber($1) }
            .dropFirst(7)
            .first
    }

    private var firstHiddenSharedSDKLabel: String? {
        allSDKLabels.dropFirst(7).first
    }

    private var visibleSharedSDKLabels: [String] {
        guard !sdkExpanded, allSDKLabels.count > 7 else { return allSDKLabels }
        return Array(allSDKLabels.prefix(7)) + ["其他"]
    }

    private func sdkItems(_ points: [SDKDistributionPoint]) -> [DistributionItem] {
        let counts = points.reduce(into: [String: Int]()) { result, point in
            let key = "API \(point.sdk)"
            result[key] = ChartInteractionSupport.addingNonnegative(point.count, to: result[key, default: 0])
        }
        let total = max(1, ChartInteractionSupport.nonnegativeSum(counts.values))
        let significantLabels = allSDKLabels.filter { Double(counts[$0, default: 0]) / Double(total) >= 0.01 }
        let labels: [String]
        if sdkExpanded || significantLabels.count <= 7 {
            labels = significantLabels
        } else {
            labels = Array(significantLabels.prefix(7)) + ["其他"]
        }
        return labels.map { label in
            if label == "其他" {
                let shown = Set(significantLabels.prefix(7))
                let value = significantLabels
                    .filter { !shown.contains($0) }
                    .reduce(0) {
                        ChartInteractionSupport.addingNonnegative(counts[$1, default: 0], to: $0)
                    }
                return DistributionItem(label: label, value: value)
            }
            return DistributionItem(label: label, value: counts[label, default: 0])
        }
    }

    private func sdkChart(
        title: String,
        points: [SDKDistributionPoint],
        angle: Binding<Double?>
    ) -> some View {
        let items = sdkItems(points)
        let total = max(1, ChartInteractionSupport.nonnegativeSum(points.map(\.count)))
        let activeLabel = items.contains(where: { $0.label == selectedSDKLabel })
            ? selectedSDKLabel
            : items.first?.label
        return DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    if allSDKLabels.count > 7 {
                        Button(sdkExpanded ? "收起" : "展开全部") {
                            toggleSDKExpansion()
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }
                }
                Text(distributionSummary(label: activeLabel, items: items, total: total))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                if items.isEmpty {
                    ContentUnavailableView("暂无有效分布数据", systemImage: "chart.pie")
                        .frame(maxWidth: .infinity, minHeight: 230)
                } else {
                    Chart(items) { item in
                        SectorMark(
                            angle: .value("应用数", item.value),
                            innerRadius: .ratio(0.56),
                            angularInset: 1.5
                        )
                        .foregroundStyle(sdkColor(item.label))
                        .opacity(activeLabel == nil || activeLabel == item.label ? 1 : 0.46)
                    }
                    .chartAngleSelection(value: angle)
                    .chartLegend(.hidden)
                    .frame(minHeight: 230)
                    .accessibilityLabel("\(title)饼图，点按扇区查看具体数据")
                }
                distributionLegend(items: items, total: total, selectedLabel: activeLabel) { label in
                    if label == "其他" {
                        // Swift Charts can trap while morphing between a collapsed
                        // sector set and a different expanded sector topology.
                        sdkExpanded = true
                        selectedSDKLabel = firstHiddenSDKLabel(in: points)
                    } else {
                        selectedSDKLabel = label
                    }
                    DashboardFeedback.selection()
                }
            }
            .onChange(of: angle.wrappedValue) { _, value in
                selectSDK(at: value, in: items, points: points)
            }
        }
    }

    private var combinedSDKChart: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("应用 SDK 分布").font(.headline)
                    Spacer()
                    if allSDKLabels.count > 7 {
                        Button(sdkExpanded ? "收起" : "展开全部") {
                            toggleSDKExpansion()
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }
                }
                HStack(alignment: .top, spacing: 12) {
                    embeddedSDKChart(
                        title: "目标 SDK",
                        points: targetSDK,
                        angle: $selectedTargetSDKAngle
                    )
                    embeddedSDKChart(
                        title: "最低 SDK",
                        points: minimumSDK,
                        angle: $selectedMinimumSDKAngle
                    )
                }
                sharedSDKLegend
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("目标 SDK 与最低 SDK 共用图例组合图表")
    }

    private func embeddedSDKChart(
        title: String,
        points: [SDKDistributionPoint],
        angle: Binding<Double?>
    ) -> some View {
        let items = sdkItems(points)
        let total = max(1, ChartInteractionSupport.nonnegativeSum(points.map(\.count)))
        let activeLabel = items.contains(where: { $0.label == selectedSDKLabel }) ? selectedSDKLabel : nil
        return VStack(spacing: 7) {
            Text(title).font(.caption.bold()).foregroundStyle(.secondary)
            Text(distributionSummary(label: activeLabel ?? items.first?.label, items: items, total: total))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Chart(items) { item in
                SectorMark(
                    angle: .value("应用数", item.value),
                    innerRadius: .ratio(0.56),
                    angularInset: 1.5
                )
                .foregroundStyle(sdkColor(item.label))
                .opacity(activeLabel == nil || activeLabel == item.label ? 1 : 0.46)
            }
            .chartAngleSelection(value: angle)
            .chartLegend(.hidden)
            .frame(minHeight: 210)
            .accessibilityLabel("\(title)分布饼图，点按扇区查看具体数据")
        }
        .frame(maxWidth: .infinity)
        .onChange(of: angle.wrappedValue) { _, value in
            selectSDK(at: value, in: items, points: points)
        }
    }

    private var sharedSDKLegend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 6)], spacing: 6) {
            ForEach(visibleSharedSDKLabels, id: \.self) { label in
                Button {
                    if label == "其他" {
                        sdkExpanded = true
                        selectedSDKLabel = firstHiddenSharedSDKLabel
                    } else {
                        selectedSDKLabel = label
                    }
                    DashboardFeedback.selection()
                } label: {
                    HStack(spacing: 7) {
                        Circle().fill(sdkColor(label)).frame(width: 9, height: 9)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(label == "其他" ? "其他（点击展开）" : label)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text("目标 \(sdkPercentage(label, in: targetSDK)) · 最低 \(sdkPercentage(label, in: minimumSDK))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedSDKLabel == label ? Color.secondary.opacity(0.12) : .clear)
                    .overlay { RoundedRectangle(cornerRadius: 9).stroke(.primary.opacity(0.1), lineWidth: 0.5) }
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(label)，目标 \(sdkPercentage(label, in: targetSDK))，最低 \(sdkPercentage(label, in: minimumSDK))")
                .accessibilityAddTraits(selectedSDKLabel == label ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("目标 SDK 与最低 SDK 共享图例")
    }

    private func sdkPercentage(_ label: String, in points: [SDKDistributionPoint]) -> String {
        let counts = points.reduce(into: [String: Int]()) { result, point in
            let key = "API \(point.sdk)"
            result[key] = ChartInteractionSupport.addingNonnegative(point.count, to: result[key, default: 0])
        }
        let total = max(1, ChartInteractionSupport.nonnegativeSum(points.map(\.count)))
        let value: Int
        if label == "其他" {
            value = allSDKLabels.dropFirst(7).reduce(0) {
                ChartInteractionSupport.addingNonnegative(counts[$1, default: 0], to: $0)
            }
        } else {
            value = counts[label, default: 0]
        }
        return "\((Double(value) / Double(total) * 100).formatted(.number.precision(.fractionLength(1))))%"
    }

    private func toggleSDKExpansion() {
        sdkExpanded.toggle()
        if !sdkExpanded,
           let selectedSDKLabel,
           !allSDKLabels.prefix(7).contains(selectedSDKLabel) {
            self.selectedSDKLabel = allSDKLabels.first
        }
        DashboardFeedback.selection()
    }

    private func selectSDK(
        at angle: Double?,
        in items: [DistributionItem],
        points: [SDKDistributionPoint]
    ) {
        guard let angle, let item = item(at: angle, in: items) else { return }
        if item.label == "其他" {
            sdkExpanded = true
            selectedSDKLabel = firstHiddenSDKLabel(in: points)
        } else {
            selectedSDKLabel = item.label
        }
        DashboardFeedback.selection()
    }

    private func ratingChart(_ distribution: RatingDistribution) -> some View {
        let items = distribution.values.sorted { $0.star > $1.star }.map {
            DistributionItem(
                label: $0.star == 1 ? "1 星与无评分" : "\($0.star) 星",
                value: max(0, $0.count),
                star: $0.star
            )
        }
        let total = max(1, ChartInteractionSupport.nonnegativeSum(items.map(\.value)))
        let selected = selectedRatingStar.flatMap { star in items.first { $0.star == star } }
        return DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("应用评分分布").font(.headline)
                Text(distributionSummary(label: selected?.label ?? items.first?.label, items: items, total: total))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                if items.contains(where: { $0.value > 0 }) {
                    Chart(items.filter { $0.value > 0 }) { item in
                        SectorMark(
                            angle: .value("应用数", item.value),
                            innerRadius: .ratio(0.56),
                            angularInset: 1.5
                        )
                        .foregroundStyle(ratingColor(item.star ?? 0))
                        .opacity(selected == nil || selected?.star == item.star ? 1 : 0.46)
                    }
                    .chartAngleSelection(value: $selectedRatingAngle)
                    .chartLegend(.hidden)
                    .frame(minHeight: 230)
                    .accessibilityLabel("应用评分分布饼图，点按扇区查看具体数据")
                } else {
                    ContentUnavailableView("暂无有效评分数据", systemImage: "chart.pie")
                        .frame(maxWidth: .infinity, minHeight: 230)
                }
                distributionLegend(items: items, total: total, selectedLabel: selected?.label) { label in
                    selectedRatingStar = items.first(where: { $0.label == label })?.star
                    DashboardFeedback.selection()
                }
            }
            .onChange(of: selectedRatingAngle) { _, value in
                guard let value, let item = item(at: value, in: items) else { return }
                selectedRatingStar = item.star
                DashboardFeedback.selection()
            }
        }
    }

    private func ratingColor(_ star: Int) -> Color {
        chartPalette[max(0, 5 - star) % chartPalette.count]
    }

    private func distributionSummary(
        label: String?,
        items: [DistributionItem],
        total: Int
    ) -> String {
        guard let label, let item = items.first(where: { $0.label == label }) else {
            return "点按扇区或图例查看具体数据"
        }
        let percent = Double(item.value) / Double(max(1, total)) * 100
        return "\(label)：\(DashboardFormat.count(item.value)) 款，\(percent.formatted(.number.precision(.fractionLength(1))))%"
    }

    private func item(at angle: Double, in items: [DistributionItem]) -> DistributionItem? {
        let total = items.reduce(0.0) { $0 + Double(max(0, $1.value)) }
        guard let angle = ChartInteractionSupport.validSelection(angle, total: total) else { return nil }
        var cumulative = 0.0
        for item in items {
            cumulative += Double(item.value)
            if angle <= cumulative { return item }
        }
        return items.last
    }

    private func distributionLegend(
        items: [DistributionItem],
        total: Int,
        selectedLabel: String?,
        action: @escaping (String) -> Void
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 6)], spacing: 6) {
            ForEach(items) { item in
                Button {
                    action(item.label)
                } label: {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(item.star.map(ratingColor) ?? sdkColor(item.label))
                            .frame(width: 9, height: 9)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.label == "其他" ? "其他（点击展开）" : item.label)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text("\(DashboardFormat.count(item.value)) · \((Double(item.value) / Double(max(1, total)) * 100).formatted(.number.precision(.fractionLength(1))))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedLabel == item.label ? Color.secondary.opacity(0.12) : .clear)
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(.primary.opacity(0.1), lineWidth: 0.5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(distributionSummary(label: item.label, items: items, total: total))
                .accessibilityAddTraits(selectedLabel == item.label ? .isSelected : [])
            }
        }
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

        if let ratingResult { rating = ratingResult.data.data }
        if let minimumResult { minimumSDK = minimumResult.data.data }
        if let targetResult { targetSDK = targetResult.data.data }
        if let historyResult { apiHistory = historyResult.data.data }
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

private struct DistributionItem: Identifiable {
    let label: String
    let value: Int
    var star: Int? = nil
    var id: String { label }
}

private struct APIHistorySeriesPoint: Identifiable {
    let date: Date
    let sdk: Int
    let percentage: Double
    var id: String { "\(sdk)-\(date.timeIntervalSince1970)" }
}

private struct APIHistoryChartCard: View {
    let history: [APIHistorySnapshot]
    let palette: [Color]

    @State private var selectedDate: Date?
    @State private var visibleDays: Double
    @State private var scrollDate: Date
    @State private var magnificationStartDays: Double?

    init(history: [APIHistorySnapshot], palette: [Color]) {
        self.history = history
        self.palette = palette
        let dates = history.compactMap { Self.parseHistoryDate($0.date) }
        let earliest = dates.min() ?? Date()
        let latest = dates.max() ?? Date()
        let span = ChartInteractionSupport.daySpan(for: dates)
        _visibleDays = State(initialValue: span)
        _scrollDate = State(initialValue: earliest)
        _selectedDate = State(initialValue: latest)
    }

    private var sdkValues: [Int] {
        Array(Set(history.flatMap { $0.percentages.keys.compactMap(Int.init).filter { $0 >= 0 } })).sorted(by: >)
    }

    private var series: [APIHistorySeriesPoint] {
        let snapshotsByDate = history.reduce(into: [Date: APIHistorySnapshot]()) { result, snapshot in
            guard let date = Self.parseHistoryDate(snapshot.date) else { return }
            result[date] = snapshot
        }
        return snapshotsByDate.keys.sorted().flatMap { date in
            guard let snapshot = snapshotsByDate[date] else { return [APIHistorySeriesPoint]() }
            return sdkValues.map { sdk in
                let value = ChartInteractionSupport.finitePercentage(snapshot.percentages[String(sdk)])
                return APIHistorySeriesPoint(date: date, sdk: sdk, percentage: value)
            }
        }
    }

    private var selectedPoints: [APIHistorySeriesPoint] {
        guard let selectedDate,
              let date = series.map(\.date).min(by: {
                  abs($0.timeIntervalSince(selectedDate)) < abs($1.timeIntervalSince(selectedDate))
              }) else { return [] }
        return series.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.sorted { $0.sdk > $1.sdk }
    }

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("API 版本占比历史").font(.headline)
                Text(selectedPoints.first?.date.formatted(date: .abbreviated, time: .omitted) ?? "点按查看数据；单指横移，双指缩放")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Chart {
                    ForEach(series) { point in
                        LineMark(
                            x: .value("日期", point.date),
                            y: .value("占比", point.percentage),
                            series: .value("API", "API \(point.sdk)")
                        )
                        .foregroundStyle(by: .value("API", "API \(point.sdk)"))
                        // Linear interpolation remains stable for sparse series and repeated
                        // zero values; Catmull-Rom can assert inside Charts during selection.
                        .interpolationMethod(.linear)
                        if let selectedDate,
                           Calendar.current.isDate(point.date, inSameDayAs: selectedDate) {
                            PointMark(x: .value("日期", point.date), y: .value("占比", point.percentage))
                                .foregroundStyle(by: .value("API", "API \(point.sdk)"))
                                .symbolSize(55)
                        }
                    }
                    if let date = selectedPoints.first?.date {
                        RuleMark(x: .value("选中日期", date))
                            .foregroundStyle(.secondary.opacity(0.55))
                            .lineStyle(.init(lineWidth: 1, dash: [4]))
                    }
                }
                .chartForegroundStyleScale(
                    domain: sdkValues.map { "API \($0)" },
                    range: sdkValues.indices.map { palette[$0 % palette.count] }
                )
                .chartXSelection(value: $selectedDate)
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: visibleDays * 24 * 60 * 60)
                .chartScrollPosition(x: $scrollDate)
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
                .chartLegend(.hidden)
                .frame(minHeight: 310)
                .simultaneousGesture(zoomGesture)
                .accessibilityLabel("API 版本占比历史折线图，可选择数据、横向拖动和双指缩放")
                historyLegend
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                guard let oldValue, let newValue,
                      !Calendar.current.isDate(oldValue, inSameDayAs: newValue) else { return }
                DashboardFeedback.selection()
            }
        }
    }

    private var fullSpanDays: Double {
        guard let first = series.map(\.date).min(), let last = series.map(\.date).max() else { return 14 }
        return ChartInteractionSupport.daySpan(for: [first, last])
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if magnificationStartDays == nil { magnificationStartDays = visibleDays }
                let start = magnificationStartDays ?? visibleDays
                if let next = ChartInteractionSupport.zoomedDaySpan(
                    start: start,
                    magnification: Double(value.magnification),
                    fullSpan: fullSpanDays
                ) {
                    visibleDays = next
                }
            }
            .onEnded { _ in
                magnificationStartDays = nil
                DashboardFeedback.selection()
            }
    }

    private var historyLegend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 6)], spacing: 6) {
            ForEach(Array(sdkValues.enumerated()), id: \.element) { index, sdk in
                let selected = selectedPoints.first(where: { $0.sdk == sdk })
                Button { DashboardFeedback.selection() } label: {
                    HStack(spacing: 7) {
                        Circle().fill(palette[index % palette.count]).frame(width: 9, height: 9)
                        Text("API \(sdk)").font(.caption).foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        Text(selected.map { "\($0.percentage.formatted(.number.precision(.fractionLength(1))))%" } ?? "—")
                            .font(.caption.weight(.medium).monospacedDigit())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 9))
                    .overlay { RoundedRectangle(cornerRadius: 9).stroke(.primary.opacity(0.1), lineWidth: 0.5) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("API \(sdk)，\(selected?.percentage.formatted() ?? "暂无") 百分比")
            }
        }
    }

    private static func parseHistoryDate(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }
}
