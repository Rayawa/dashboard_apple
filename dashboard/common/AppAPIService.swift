import Foundation

private struct SubmitAppBody: Encodable {
    struct CommentInfo: Encodable {
        let platform: String
        let user: String?
    }

    let appId: String?
    let pkgName: String?
    let comment: CommentInfo
}

enum APIError: LocalizedError {
    case invalidInput(String)
    case invalidResponse
    case network
    case responseTooLarge
    case server(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message), .server(let message), .notFound(let message):
            message
        case .invalidResponse:
            "服务返回了无法解析的数据"
        case .network:
            "网络连接失败，请稍后重试"
        case .responseTooLarge:
            "服务返回的数据超过允许大小"
        }
    }
}

enum AppAPIService {
    private static let allowedSorts = Set([
        "updated_at", "download_count", "total_star_rating_count", "size_bytes", "listed_at",
    ])
    private static let allowedSearchKeys = Set([
        "name", "pkg_name", "developer_name", "kind_name", "kind_type_name", "tag_name",
        "download_count", "average_rating", "total_star_rating_count", "minsdk", "target_sdk",
        "main_device_codes",
    ])

    private enum CacheTTL {
        static let home: TimeInterval = 5 * 60
        static let list: TimeInterval = 2 * 60
        static let detail: TimeInterval = 30 * 60
        static let chart: TimeInterval = 30 * 60
        static let fallback: TimeInterval = 30 * 24 * 60 * 60
    }

    private static let apiBase = DashboardURLs.sAPIBase
    private static let maximumResponseSize = 8_000_000
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpAdditionalHeaders = ["User-Agent": UAProvider.customUserAgent]
        return URLSession(configuration: configuration)
    }()
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    static func submitPlatform() -> String {
#if os(macOS)
        "dashboard-apple/\(DashboardMeta.appVersion)-macOS"
#else
        "dashboard-apple/\(DashboardMeta.appVersion)-iOS"
#endif
    }

    static func marketInfo(force: Bool = false) async throws -> APIDataResult<APIEnvelope<MarketInfo>> {
        try await cachedGET(
            pathComponents: ["market_info"],
            freshFor: CacheTTL.home,
            force: force
        )
    }

    static func appsPage(
        _ query: AppsPageQuery,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<PageInfo<MarketApp>>> {
        try validateQuery(query)
        var items = [
            URLQueryItem(name: "page_size", value: String(query.pageSize)),
            URLQueryItem(name: "detail", value: "true"),
            URLQueryItem(name: "sort", value: query.sort),
            URLQueryItem(name: "desc", value: String(query.descending)),
            URLQueryItem(name: "exclude_huawei", value: String(query.excludeHuawei)),
            URLQueryItem(name: "exclude_atomic", value: String(query.excludeAtomic)),
        ]
        if let key = query.searchKey, let value = query.searchValue, !value.isEmpty {
            items.append(URLQueryItem(name: "search_key", value: key))
            items.append(URLQueryItem(name: "search_value", value: value))
            items.append(URLQueryItem(name: "search_exact", value: String(query.exact)))
        }
        return try await cachedGET(
            pathComponents: ["apps", "list", String(query.page)],
            queryItems: items,
            freshFor: CacheTTL.list,
            force: force
        )
    }

    static func appsQuery(
        _ query: AppsPageQuery,
        expression: SearchExpression,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<PageInfo<MarketApp>>> {
        try validateQuery(query)
        try validateExpression(expression)
        let items = [
            URLQueryItem(name: "page", value: String(query.page)),
            URLQueryItem(name: "page_size", value: String(query.pageSize)),
            URLQueryItem(name: "detail", value: "true"),
            URLQueryItem(name: "sort", value: query.sort),
            URLQueryItem(name: "desc", value: String(query.descending)),
        ]
        let url = try makeURL(pathComponents: ["apps", "query"], queryItems: items)
        let body = try encoder.encode(expression)
        let key = "POST:\(url.absoluteString):\(String(decoding: body, as: UTF8.self))"
        let cached = await MarketCache.shared.read(
            APIEnvelope<PageInfo<MarketApp>>.self,
            key: key,
            freshFor: CacheTTL.list,
            maximumAge: CacheTTL.fallback
        )
        if !force, let cached, !cached.isStale { return cached }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            let data = try await perform(request, action: "高级搜索")
            let value: APIEnvelope<PageInfo<MarketApp>> = try decode(data)
            await MarketCache.shared.write(value, key: key)
            return APIDataResult(data: value, isFromCache: false, isStale: false, cachedAt: Date())
        } catch {
            if let cached {
                return APIDataResult(data: cached.data, isFromCache: true, isStale: true, cachedAt: cached.cachedAt)
            }
            throw error
        }
    }

    static func appDetail(
        appId: String,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<AppDetailPayload>> {
        let validatedID = try validatedAppID(appId)
        return try await cachedGET(
            pathComponents: ["apps", "app_id", validatedID],
            queryItems: [URLQueryItem(name: "use_cache", value: String(!force))],
            freshFor: CacheTTL.detail,
            force: force,
            cacheIdentity: "detail:id:\(validatedID)"
        )
    }

    static func appDetail(
        packageName: String,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<AppDetailPayload>> {
        let package = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        try validatePackageName(package)
        return try await cachedGET(
            pathComponents: ["apps", "pkg_name", package],
            queryItems: [URLQueryItem(name: "use_cache", value: String(!force))],
            freshFor: CacheTTL.detail,
            force: force,
            cacheIdentity: "detail:package:\(package)"
        )
    }

    static func ratingDistribution(force: Bool = false) async throws -> APIDataResult<APIEnvelope<RatingDistribution>> {
        try await cachedGET(pathComponents: ["charts", "rating"], freshFor: CacheTTL.chart, force: force)
    }

    static func sdkDistribution(
        target: Bool,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<[SDKDistributionPoint]>> {
        try await cachedGET(
            pathComponents: ["charts", target ? "target_sdk" : "min_sdk"],
            freshFor: CacheTTL.chart,
            force: force
        )
    }

    static func apiHistory(force: Bool = false) async throws -> APIDataResult<APIEnvelope<[APIHistorySnapshot]>> {
        try await cachedGET(
            pathComponents: ["charts", "api_history"],
            freshFor: CacheTTL.chart,
            force: force
        )
    }

    static func dailyMaxDownloads(force: Bool = false) async throws -> APIDataResult<APIEnvelope<[DailyMaxDownloadApp]>> {
        try await cachedGET(
            pathComponents: ["rankings", "max_download"],
            freshFor: CacheTTL.home,
            force: force
        )
    }

    static func downloadGrowth(
        days: Int,
        limit: Int = 10,
        page: Int = 1,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<[DownloadGrowthApp]>> {
        guard [1, 7, 30].contains(days) else {
            throw APIError.invalidInput("下载增长周期无效")
        }
        return try await cachedGET(
            pathComponents: ["rankings", "download_increase"],
            queryItems: [
                URLQueryItem(name: "days", value: String(days)),
                URLQueryItem(name: "limit", value: String(max(1, min(limit, 100)))),
                URLQueryItem(name: "page", value: String(max(1, page))),
            ],
            freshFor: CacheTTL.chart,
            force: force
        )
    }

    static func developerRanking(
        limit: Int = 10,
        page: Int = 1,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<[DeveloperRankingEntry]>> {
        try await cachedGET(
            pathComponents: ["rankings", "developers"],
            queryItems: [
                URLQueryItem(name: "limit", value: String(max(1, min(limit, 100)))),
                URLQueryItem(name: "page", value: String(max(1, page))),
            ],
            freshFor: CacheTTL.home,
            force: force
        )
    }

    static func appMetrics(
        packageName: String,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<[AppMetric]>> {
        let package = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        try validatePackageName(package)
        return try await cachedGET(
            pathComponents: ["apps", "metrics", package],
            freshFor: CacheTTL.detail,
            force: force
        )
    }

    static func ratingHistory(
        packageName: String,
        force: Bool = false
    ) async throws -> APIDataResult<APIEnvelope<[AppRatingHistory]>> {
        let package = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        try validatePackageName(package)
        return try await cachedGET(
            pathComponents: ["rankings", "rate_history"],
            queryItems: [URLQueryItem(name: "pkg_name", value: package)],
            freshFor: CacheTTL.detail,
            force: force
        )
    }

    static func dashboardConfig() async -> DashboardVisibilityConfig {
        do {
            let url = try makeURL(pathComponents: ["dashboard", "config"])
            let data = try await perform(URLRequest(url: url), action: "看板配置")
            let response: APIEnvelope<DashboardVisibilityPayload> = try decode(data)
            guard response.success else { return .restricted }
            let payload = response.data
            return DashboardVisibilityConfig(
                showInstallCount: payload.showInstallCount == true,
                showTotalDownloadRanking: payload.showTotalDownloadRanking == true,
                showDownloadHistory: payload.showDownloadHistory == true,
                showNonHuaweiDownloadRanking: payload.showNonHuaweiDownloadRanking == true,
                showAppDownloadMetrics: payload.showAppDownloadMetrics == true,
                showTSite: payload.showTSite == true
            )
        } catch {
            return .restricted
        }
    }

    static func submitApp(
        packageName: String,
        appId: String,
        remark: String
    ) async throws -> APIEnvelope<AppDetailPayload> {
        let package = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawAppID = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = remark.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !package.isEmpty || !rawAppID.isEmpty else {
            throw APIError.invalidInput("请输入包名或应用 ID")
        }
        guard user.count <= 120 else {
            throw APIError.invalidInput("投稿用户名不能超过 120 个字符")
        }
        if !package.isEmpty { try validatePackageName(package) }
        let appID = rawAppID.isEmpty ? nil : try validatedAppID(rawAppID)
        let payload = SubmitAppBody(
            appId: package.isEmpty ? appID : nil,
            pkgName: package.isEmpty ? nil : package,
            comment: .init(platform: submitPlatform(), user: user.isEmpty ? nil : user)
        )
        let url = try makeURL(pathComponents: ["submit"])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        let data = try await perform(request, action: "提交")
        let response: APIEnvelope<AppDetailPayload> = try decode(data)
        guard response.success else { throw APIError.server("提交未成功") }
        return response
    }

    static func clearAPICache() async throws {
        try await MarketCache.shared.removeAll()
    }

    static func apiCacheSize() async -> Int64 {
        await MarketCache.shared.size()
    }

    private static func validatePackageName(_ packageName: String) throws {
        guard !packageName.isEmpty,
              packageName.count <= 255,
              packageName.range(
                  of: "^[A-Za-z0-9_]+(?:[.-][A-Za-z0-9_]+)+$",
                  options: .regularExpression
              ) != nil else {
            throw APIError.invalidInput("包名格式无效")
        }
    }

    private static func validateQuery(_ query: AppsPageQuery) throws {
        guard (1...100).contains(query.pageSize), (1...1_000_000).contains(query.page) else {
            throw APIError.invalidInput("分页参数无效")
        }
        guard allowedSorts.contains(query.sort) else {
            throw APIError.invalidInput("排序字段无效")
        }
        if let key = query.searchKey {
            guard allowedSearchKeys.contains(key),
                  let value = query.searchValue,
                  !value.isEmpty,
                  value.count <= 512 else {
                throw APIError.invalidInput("筛选参数无效")
            }
        }
    }

    private static func validateExpression(_ expression: SearchExpression) throws {
        guard (expression.and == nil) != (expression.or == nil) else {
            throw APIError.invalidInput("高级搜索必须选择一种条件关系")
        }
        let conditions = expression.and ?? expression.or ?? []
        guard (1...12).contains(conditions.count) else {
            throw APIError.invalidInput("高级搜索条件数量无效")
        }
        for condition in conditions {
            guard allowedSearchKeys.contains(condition.key) else {
                throw APIError.invalidInput("高级搜索字段无效")
            }
            if condition.op.needsValue {
                guard let value = condition.value?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !value.isEmpty,
                      value.count <= 512 else {
                    throw APIError.invalidInput("高级搜索条件值无效")
                }
            }
        }
    }

    private static func validatedAppID(_ appID: String) throws -> String {
        let trimmed = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.first == "C" || trimmed.first == "c" ? String(trimmed.dropFirst()) : trimmed
        guard digits.range(of: "^[0-9]{5,32}$", options: .regularExpression) != nil else {
            throw APIError.invalidInput("应用 ID 格式无效")
        }
        return "C\(digits)"
    }

    private static func makeURL(
        pathComponents: [String],
        queryItems: [URLQueryItem] = []
    ) throws -> URL {
        let url = pathComponents.reduce(apiBase) { partialURL, component in
            partialURL.appending(path: component)
        }
        guard !queryItems.isEmpty else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        guard let result = components?.url else { throw APIError.invalidInput("无法构造请求地址") }
        return result
    }

    private static func cachedGET<Value: Codable & Sendable>(
        pathComponents: [String],
        queryItems: [URLQueryItem] = [],
        freshFor: TimeInterval,
        force: Bool,
        cacheIdentity: String? = nil
    ) async throws -> APIDataResult<Value> {
        let url = try makeURL(pathComponents: pathComponents, queryItems: queryItems)
        let key = cacheIdentity ?? url.absoluteString
        let cached = await MarketCache.shared.read(
            Value.self,
            key: key,
            freshFor: freshFor,
            maximumAge: CacheTTL.fallback
        )
        if !force, let cached, !cached.isStale { return cached }

        do {
            let data = try await perform(URLRequest(url: url), action: "网络请求")
            let value: Value = try decode(data)
            await MarketCache.shared.write(value, key: key)
            return APIDataResult(data: value, isFromCache: false, isStale: false, cachedAt: Date())
        } catch {
            if let cached {
                return APIDataResult(
                    data: cached.data,
                    isFromCache: true,
                    isStale: true,
                    cachedAt: cached.cachedAt
                )
            }
            throw error
        }
    }

    private static func decode<Value: Decodable>(_ data: Data) throws -> Value {
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
#if DEBUG
            print("[Dashboard][API] JSON decode failed: \(error)")
#endif
            throw APIError.invalidResponse
        }
    }

    private static func perform(_ request: URLRequest, action: String) async throws -> Data {
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            if httpResponse.statusCode == 404 {
                throw APIError.notFound("\(action)未找到对应应用")
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.server("\(action)失败，服务返回 \(httpResponse.statusCode)")
            }
            if httpResponse.expectedContentLength > Int64(maximumResponseSize) {
                throw APIError.responseTooLarge
            }

            var data = Data()
            data.reserveCapacity(max(0, Int(httpResponse.expectedContentLength)))
            for try await byte in bytes {
                guard data.count < maximumResponseSize else { throw APIError.responseTooLarge }
                data.append(byte)
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network
        }
    }
}
