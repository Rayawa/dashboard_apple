import Charts
import SwiftUI

struct NativeAppDetailView: View {
    let target: AppDetailTarget

    @Environment(\.openURL) private var openURL
    @Environment(\.dashboardVisibility) private var visibility
    @State private var app: MarketApp?
    @State private var metrics: [AppMetric] = []
    @State private var ratings: [AppRatingHistory] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var supplementalWarning: String?
    @State private var staleDate: Date?

    init(target: AppDetailTarget) {
        self.target = target
        _app = State(initialValue: target.preview)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let staleDate { OfflineCacheBanner(cachedAt: staleDate) }
                if let supplementalWarning {
                    Label(supplementalWarning, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLoading, app == nil {
                    LoadingStateView(text: "正在加载应用详情…")
                } else if let errorMessage, app == nil {
                    ErrorStateView(message: errorMessage) {
                        Task { await load(force: true) }
                    }
                } else if let app {
                    identity(app)
                    information(app)
                    ratingBreakdown(app)
                    description(app)
                    if !app.screenshots.isEmpty { screenshots(app) }
                    if visibility.showAppDownloadMetrics, visibility.showDownloadHistory, !metrics.isEmpty {
                        downloadChart
                    }
                    if !ratings.isEmpty { ratingChart }
                }
            }
            .padding()
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .dashboardPage()
        .navigationTitle(app?.name ?? "应用详情")
#if os(macOS)
        .navigationSubtitle(app?.pkgName ?? "")
#endif
        .refreshable { await load(force: true) }
        .toolbar {
            if let app {
                ToolbarItemGroup(placement: .primaryAction) {
                    ShareLink(
                        item: DashboardURLs.appDetailShareURL(appId: app.appId, useTSite: visibility.showTSite),
                        subject: Text(app.name)
                    )
                    Button("刷新", systemImage: "arrow.clockwise") {
                        Task { await load(force: true) }
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task { await load(force: false) }
    }

    private func identity(_ app: MarketApp) -> some View {
        DashboardCard {
            VStack(spacing: 14) {
                AppIconView(app: app, size: 100)
                Text(app.name)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(app.developerName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { appActions(app) }
                    VStack(spacing: 10) { appActions(app) }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func appActions(_ app: MarketApp) -> some View {
        Button("在华为应用市场打开", systemImage: "bag") {
            openURL(DashboardURLs.appGalleryDetail(appId: app.allianceAppId ?? app.appId))
        }
        .buttonStyle(.borderedProminent)
        if let privacy = app.privacyUrl.flatMap(URL.init(string:)), privacy.scheme == "https" {
            Link(destination: privacy) {
                Label("隐私政策", systemImage: "hand.raised")
            }
                .buttonStyle(.bordered)
        }
    }

    private func information(_ app: MarketApp) -> some View {
        var fields: [(String, String)] = [
            ("应用 ID", app.appId),
            ("包名", app.pkgName),
            ("开发者", app.developerName),
            ("分类", "\(app.kindTypeName) · \(app.kindName)"),
            ("版本", "\(app.version) (\(app.versionCode))"),
            ("应用大小", DashboardFormat.bytes(app.sizeBytes)),
            ("最低 SDK", String(app.minsdk)),
            ("目标 SDK", String(app.targetSdk)),
            ("编译 SDK", String(app.compileSdkVersion)),
            ("最低 API 版本", app.minHmosApiLevel.map(String.init) ?? "-"),
            ("评分", app.displayRating.map { String(format: "%.2f / 5", $0) } ?? "-"),
            ("评分数量", DashboardFormat.count(app.totalStarRatingCount ?? 0)),
            ("供应商", app.supplier),
            ("标签", app.tagName),
            ("支持设备", app.mainDeviceCodes.joined(separator: "、")),
            ("应用内购买", app.iap == true ? "支持" : "不支持"),
            ("付费状态", app.isPay == true ? "付费应用" : "免费应用"),
            ("价格", app.price?.value == "0" ? "免费" : (app.price?.value ?? "-")),
            ("发行国家/地区", app.releaseCountries?.joined(separator: "、") ?? "-"),
            ("备案主体", app.recordalEntityName ?? app.recordalEntityTitle ?? "-"),
            ("备案信息", app.appRecordalInfo ?? "-"),
            ("上架时间", DashboardFormat.dateTime(app.listedAt)),
            ("数据更新", DashboardFormat.dateTime(app.updatedAt)),
        ]
        if visibility.showAppDownloadMetrics {
            fields.insert(("下载量", DashboardFormat.count(app.downloadCount)), at: 10)
        }

        return DashboardCard {
            DashboardSectionTitle(title: "详细信息", systemImage: "info.circle.fill")
                .padding(.bottom, 4)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 10)], spacing: 10) {
                ForEach(fields, id: \.0) { field in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(field.0).font(.caption.bold()).foregroundStyle(.tint)
                        Text(field.1.isEmpty ? "-" : field.1)
                            .font(.callout)
                            .lineLimit(2)
                            .textSelection(.enabled)
                        Spacer(minLength: 0)
                    }
                    .padding(11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private func ratingBreakdown(_ app: MarketApp) -> some View {
        let counts = [
            (star: 5, count: max(0, app.star5RatingCount ?? 0)),
            (star: 4, count: max(0, app.star4RatingCount ?? 0)),
            (star: 3, count: max(0, app.star3RatingCount ?? 0)),
            (star: 2, count: max(0, app.star2RatingCount ?? 0)),
            (star: 1, count: max(0, app.star1RatingCount ?? 0)),
        ]
        if counts.contains(where: { $0.count > 0 }) {
            let maximumCount = max(1, counts.map(\.count).max() ?? 1)
            DashboardCard {
                HStack {
                    DashboardSectionTitle(title: "逐星评分数量", systemImage: "star.fill", tint: .orange)
                    Spacer()
                    Text("共 \(DashboardFormat.count(max(0, app.totalStarRatingCount ?? 0))) 条")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 3) {
                    ForEach(counts, id: \.star) { item in
                        Button {
                            DashboardFeedback.selection()
                        } label: {
                            HStack(spacing: 10) {
                                Text("\(item.star) 星")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 38, alignment: .leading)
                                ProgressView(value: Double(item.count), total: Double(maximumCount))
                                    .tint(.orange)
                                Text(DashboardFormat.count(item.count))
                                    .font(.caption.monospacedDigit())
                                    .frame(width: 70, alignment: .trailing)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(RatingBreakdownRowButtonStyle())
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(item.star) 星评分 \(item.count) 条")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("逐星评分数量")
            }
        }
    }

    private func description(_ app: MarketApp) -> some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                DashboardSectionTitle(title: "应用介绍", systemImage: "text.alignleft")
                Text(app.description.isEmpty ? "暂无介绍" : app.description)
                    .lineSpacing(5)
                    .textSelection(.enabled)
                if let features = app.newFeatures, !features.isEmpty {
                    Divider()
                    Text("新版特性").font(.headline)
                    Text(features).lineSpacing(5).textSelection(.enabled)
                }
            }
        }
    }

    private func screenshots(_ app: MarketApp) -> some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                DashboardSectionTitle(title: "应用截图", systemImage: "photo.on.rectangle.angled")
                ScreenshotCarousel(appName: app.name, screenshots: app.screenshots)
            }
        }
    }

    private var downloadChart: some View {
        let points = metrics.compactMap { metric -> TrendPoint? in
            guard metric.downloadCount >= 0, let date = parseDate(metric.createdAt) else { return nil }
            return TrendPoint(
                date: date,
                value: Double(metric.downloadCount),
                detail: "版本 \(metric.version) · \(DashboardFormat.count(metric.downloadCount)) 次"
            )
        }.sorted { $0.date < $1.date }
        return TrendChartCard(
            title: "下载量趋势",
            tint: .blue,
            points: filterDownloadOutliers(points)
        )
    }

    private var ratingChart: some View {
        TrendChartCard(
            title: "评分趋势",
            tint: .orange,
            points: ratings.compactMap {
                let value = $0.cumulativeAvgRatingHighPrec.value
                guard (0...5).contains(value), let date = parseDate($0.reportDate) else { return nil }
                return TrendPoint(date: date, value: value, detail: "累计 \(DashboardFormat.count($0.cumulativeTotalCount)) 条评分")
            }
        )
    }

    @MainActor
    private func load(force: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        supplementalWarning = nil
        defer { isLoading = false }
        do {
            let result: APIDataResult<APIEnvelope<AppDetailPayload>>
            if let appId = target.appId {
                result = try await AppAPIService.appDetail(appId: appId, force: force)
            } else if let packageName = target.packageName {
                result = try await AppAPIService.appDetail(packageName: packageName, force: force)
            } else {
                throw APIError.invalidInput("缺少应用标识")
            }
            let loadedApp = result.data.data.fullInfo
            app = loadedApp
            var staleDates = [result.isStale ? result.cachedAt : nil]
            var failedSupplementalRequests = 0

            async let ratingsRequest = try? AppAPIService.ratingHistory(packageName: loadedApp.pkgName, force: force)
            if visibility.showAppDownloadMetrics, visibility.showDownloadHistory {
                if let metricResult = try? await AppAPIService.appMetrics(packageName: loadedApp.pkgName, force: force) {
                    metrics = metricResult.data.data.stableUniqued(by: \AppMetric.id)
                    if metricResult.isStale { staleDates.append(metricResult.cachedAt) }
                } else {
                    failedSupplementalRequests += 1
                }
            }
            if let ratingResult = await ratingsRequest {
                ratings = ratingResult.data.data.stableUniqued(by: \AppRatingHistory.id)
                if ratingResult.isStale { staleDates.append(ratingResult.cachedAt) }
            } else {
                failedSupplementalRequests += 1
            }
            staleDate = staleDates.compactMap { $0 }.min()
            if failedSupplementalRequests > 0 {
                supplementalWarning = "有 \(failedSupplementalRequests) 项历史图表暂时不可用，应用基本信息仍可正常查看"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseDate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let result = iso.date(from: raw) { return result }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }
}

private struct RatingBreakdownRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .background(
                configuration.isPressed ? Color.orange.opacity(0.08) : .clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ScreenshotCarousel: View {
    let appName: String
    let screenshots: [ScreenshotInfo]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentIndex = 0
    @State private var settledScreenshotIDs: Set<String> = []
    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0

    private var isLandscape: Bool {
        guard let first = screenshots.first else { return false }
        let normalized = first.resolution
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "x", with: "*")
            .replacingOccurrences(of: "X", with: "*")
        let parts = normalized.split(separator: "*").compactMap { Double($0) }
        guard parts.count >= 2 else { return false }
        let width = first.rotated == 0 ? parts[0] : parts[1]
        let height = first.rotated == 0 ? parts[1] : parts[0]
        return width > height
    }

    private var carouselRatio: CGFloat {
        if isLandscape { return 2 }
        return horizontalSizeClass == .compact ? 0.62 : 1.1
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                ZStack {
                    ForEach(Array(screenshots.enumerated()), id: \.offset) { index, screenshot in
                        let position = relativePosition(of: index)
                        if abs(position) <= 1 {
                            screenshotCard(screenshot, index: index)
                                .frame(width: cardWidth(in: proxy.size.width))
                                .scaleEffect(cardScale(position: position, width: proxy.size.width))
                                .opacity(cardOpacity(position: position, width: proxy.size.width))
                                .offset(x: cardOffset(position: position, width: proxy.size.width))
                                .zIndex(cardZIndex(position: position))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(dragGesture(width: proxy.size.width))
            }
            .aspectRatio(carouselRatio, contentMode: .fit)
            .frame(maxWidth: 760)
            .clipped()

            if screenshots.count > 1 {
                HStack(spacing: 7) {
                    ForEach(screenshots.indices, id: \.self) { index in
                        Button {
                            select(index)
                        } label: {
                            Capsule()
                                .fill(index == currentIndex ? Color.accentColor : Color.secondary.opacity(0.28))
                                .frame(width: index == currentIndex ? 22 : 7, height: 7)
                                .animation(.easeOut(duration: 0.18), value: currentIndex)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("切换到第 \(index + 1) 张应用截图")
                        .accessibilityAddTraits(index == currentIndex ? .isSelected : [])
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("当前为第 \(currentIndex + 1) 张，共 \(screenshots.count) 张应用截图")
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: "\(currentIndex)-\(settledScreenshotIDs.count)-\(isDragging)") {
            guard screenshots.count > 1,
                  settledScreenshotIDs.count == screenshots.count,
                  !isDragging else { return }
            do {
                try await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled else { return }
                await MainActor.run { advance(by: 1, feedback: false) }
            } catch {}
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("可自动播放和左右滑动的叠加应用截图")
    }

    private func screenshotCard(_ screenshot: ScreenshotInfo, index: Int) -> some View {
        AsyncImage(url: screenshot.remoteURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
                    .onAppear { settledScreenshotIDs.insert(screenshotKey(screenshot, index: index)) }
            case .failure:
                ContentUnavailableView("截图加载失败", systemImage: "photo.badge.exclamationmark")
                    .onAppear { settledScreenshotIDs.insert(screenshotKey(screenshot, index: index)) }
            default:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(.primary.opacity(0.1), lineWidth: 0.5) }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("第 \(index + 1) 张 \(appName) 应用截图")
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { _ in
                if !isDragging { isDragging = true }
            }
            .updating($dragOffset) { value, state, _ in
                state = max(-width, min(width, value.translation.width))
            }
            .onEnded { value in
                isDragging = false
                let threshold = max(52, width * 0.18)
                let projected = value.predictedEndTranslation.width
                if value.translation.width < -threshold || projected < -threshold * 1.7 {
                    advance(by: 1)
                } else if value.translation.width > threshold || projected > threshold * 1.7 {
                    advance(by: -1)
                }
            }
    }

    private func cardWidth(in width: CGFloat) -> CGFloat {
        if isLandscape { return width * 0.88 }
        return horizontalSizeClass == .compact ? width * 0.91 : width * 0.52
    }

    private func screenshotKey(_ screenshot: ScreenshotInfo, index: Int) -> String {
        "\(screenshot.id)-\(index)"
    }

    private func relativePosition(of index: Int) -> Int {
        guard screenshots.count > 1, index != currentIndex else { return 0 }
        let forward = (index - currentIndex + screenshots.count) % screenshots.count
        if forward == 1 { return 1 }
        if forward == screenshots.count - 1 { return -1 }
        return 2
    }

    private func cardOffset(position: Int, width: CGFloat) -> CGFloat {
        if position == 0 { return dragOffset }
        let resolvedPosition = screenshots.count == 2 && dragOffset > 0 ? -position : position
        let sideOffset = width * (isLandscape ? 0.12 : 0.32)
        let revealing = (dragOffset < 0 && resolvedPosition == 1) ||
            (dragOffset > 0 && resolvedPosition == -1)
        let progress = min(1, abs(dragOffset) / max(1, width))
        return CGFloat(resolvedPosition) * sideOffset * (revealing ? 1 - progress : 1)
    }

    private func cardScale(position: Int, width: CGFloat) -> CGFloat {
        guard position != 0 else { return 1 }
        let resolvedPosition = screenshots.count == 2 && dragOffset > 0 ? -position : position
        let revealing = (dragOffset < 0 && resolvedPosition == 1) ||
            (dragOffset > 0 && resolvedPosition == -1)
        let progress = min(1, abs(dragOffset) / max(1, width))
        return revealing ? 0.9 + progress * 0.1 : 0.9
    }

    private func cardOpacity(position: Int, width: CGFloat) -> Double {
        guard position != 0 else { return 1 }
        let resolvedPosition = screenshots.count == 2 && dragOffset > 0 ? -position : position
        let revealing = (dragOffset < 0 && resolvedPosition == 1) ||
            (dragOffset > 0 && resolvedPosition == -1)
        let progress = min(1, abs(dragOffset) / max(1, width))
        return revealing ? 0.68 + Double(progress) * 0.32 : 0.68
    }

    private func cardZIndex(position: Int) -> Double {
        position == 0 ? 3 : 1
    }

    private func advance(by amount: Int, feedback: Bool = true) {
        guard screenshots.count > 1 else { return }
        if feedback { DashboardFeedback.selection() }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            currentIndex = (currentIndex + amount + screenshots.count) % screenshots.count
        }
    }

    private func select(_ index: Int) {
        guard index != currentIndex else { return }
        DashboardFeedback.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
            currentIndex = index
        }
    }
}

private struct TrendPoint: Identifiable {
    let date: Date
    let value: Double
    let detail: String
    var id: Date { date }
}

private struct TrendChartCard: View {
    let title: String
    let tint: Color
    let points: [TrendPoint]
    @State private var selectedDate: Date?
    @State private var visibleDays: Double
    @State private var scrollDate: Date
    @State private var magnificationStartDays: Double?

    init(title: String, tint: Color, points: [TrendPoint]) {
        self.title = title
        self.tint = tint
        self.points = points
        let earliest = points.min(by: { $0.date < $1.date })?.date ?? Date()
        let latest = points.max(by: { $0.date < $1.date })?.date ?? Date()
        let span = ChartInteractionSupport.daySpan(for: [earliest, latest])
        _visibleDays = State(initialValue: span)
        _scrollDate = State(initialValue: earliest)
        _selectedDate = State(initialValue: latest)
    }

    var body: some View {
        let sorted = downsampleTrendPoints(points.sorted { $0.date < $1.date }, maximumCount: 360)
        DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.title2.bold())
                if let selected = selectedPoint(in: sorted) {
                    Text("\(selected.date.formatted(date: .abbreviated, time: .omitted)) · \(selected.value.formatted()) · \(selected.detail)")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("拖动图表查看具体数据")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Chart(sorted) { point in
                    AreaMark(x: .value("日期", point.date), y: .value("数值", point.value))
                        .foregroundStyle(LinearGradient(colors: [tint.opacity(0.28), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("日期", point.date), y: .value("数值", point.value))
                        .foregroundStyle(tint)
                        .lineStyle(.init(lineWidth: 2))
                    if let selectedDate, Calendar.current.isDate(point.date, inSameDayAs: selectedDate) {
                        PointMark(x: .value("日期", point.date), y: .value("数值", point.value))
                            .foregroundStyle(tint).symbolSize(70)
                    }
                }
                .chartXSelection(value: $selectedDate)
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: visibleDays * 24 * 60 * 60)
                .chartScrollPosition(x: $scrollDate)
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(minHeight: 280)
                .simultaneousGesture(zoomGesture)
                .accessibilityLabel("\(title)，点按查看数据，单指横移，双指缩放")
                Text("点按查看数据；单指横移，双指缩放 · 当前显示约 \(Int(visibleDays)) 天")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                guard let oldValue, let newValue,
                      !Calendar.current.isDate(oldValue, inSameDayAs: newValue) else { return }
                DashboardFeedback.selection()
            }
        }
    }

    private var fullSpanDays: Double {
        guard let first = points.map(\.date).min(), let last = points.map(\.date).max() else { return 14 }
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

    private func selectedPoint(in points: [TrendPoint]) -> TrendPoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

}

private func filterDownloadOutliers(_ points: [TrendPoint]) -> [TrendPoint] {
    let window = 4
    let outlierThreshold = 0.35
    let baselineTolerance = 0.12
    guard points.count >= 5 else { return points }

    func relativeDifference(_ left: Double, _ right: Double) -> Double {
        abs(left - right) / max(1, abs(right))
    }

    func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2
            : sorted[middle]
    }

    return points.enumerated().compactMap { index, point in
        let start = max(0, index - window)
        let end = min(points.count, index + window + 1)
        guard index - start >= 2, end - index - 1 >= 2 else { return point }
        let baseline = median(points[start..<end].map(\.value))
        guard relativeDifference(point.value, baseline) >= outlierThreshold else { return point }
        let matchesBefore = points[start..<index].contains {
            relativeDifference($0.value, baseline) <= baselineTolerance
        }
        let matchesAfter = points[(index + 1)..<end].contains {
            relativeDifference($0.value, baseline) <= baselineTolerance
        }
        return matchesBefore && matchesAfter ? nil : point
    }
}

private func downsampleTrendPoints(_ points: [TrendPoint], maximumCount: Int) -> [TrendPoint] {
    guard maximumCount >= 3, points.count > maximumCount else { return points }
    var sampled = [points[0]]
    let bucketSize = Double(points.count - 2) / Double(maximumCount - 2)
    var anchorIndex = 0

    for bucket in 0..<(maximumCount - 2) {
        let averageStart = min(points.count - 1, Int(floor(Double(bucket + 1) * bucketSize)) + 1)
        let averageEnd = min(points.count, Int(floor(Double(bucket + 2) * bucketSize)) + 1)
        let averageRange = averageStart..<max(averageStart + 1, averageEnd)
        let averageX = averageRange.map { points[$0].date.timeIntervalSince1970 }.reduce(0, +) / Double(averageRange.count)
        let averageY = averageRange.map { points[$0].value }.reduce(0, +) / Double(averageRange.count)

        let rangeStart = min(points.count - 2, Int(floor(Double(bucket) * bucketSize)) + 1)
        let rangeEnd = min(points.count - 1, Int(floor(Double(bucket + 1) * bucketSize)) + 1)
        let anchor = points[anchorIndex]
        let anchorX = anchor.date.timeIntervalSince1970
        var selectedIndex = rangeStart
        var largestArea = -Double.infinity

        if rangeStart < rangeEnd {
            for index in rangeStart..<rangeEnd {
                let pointX = points[index].date.timeIntervalSince1970
                let area = abs(
                    (anchorX - averageX) * (points[index].value - anchor.value)
                    - (anchorX - pointX) * (averageY - anchor.value)
                )
                if area > largestArea {
                    largestArea = area
                    selectedIndex = index
                }
            }
        }
        sampled.append(points[selectedIndex])
        anchorIndex = selectedIndex
    }

    sampled.append(points[points.count - 1])
    return sampled
}
