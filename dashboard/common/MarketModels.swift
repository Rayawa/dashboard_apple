import Foundation

nonisolated struct APIEnvelope<Value: Codable & Sendable>: Codable, Sendable {
    let success: Bool
    let data: Value
    let total: Int?
    let limit: Int?
    let timestamp: String?
}

nonisolated struct APIDataResult<Value: Codable & Sendable>: Sendable {
    let data: Value
    let isFromCache: Bool
    let isStale: Bool
    let cachedAt: Date?
}

nonisolated struct MarketCountInfo: Codable, Hashable, Sendable {
    let apps: Int
    let atomicServices: Int
    let maxDownloadCount: Int64
    let total: Int
}

nonisolated struct SyncDuration: Codable, Hashable, Sendable {
    let secs: Int
    let nanos: Int

    var timeInterval: TimeInterval {
        TimeInterval(secs) + TimeInterval(nanos) / 1_000_000_000
    }
}

nonisolated struct SyncStatusInfo: Codable, Hashable, Sendable {
    let elapsedTime: SyncDuration?
    let estimatedTotalTime: SyncDuration?
    let isSyncingAll: Bool
    let nextSyncCountdown: Int?
    let progress: [Int]?
    let totalFailed: Int
    let totalInserted: Int
    let totalProcessed: Int
    let totalSkipped: Int
}

nonisolated struct MarketInfo: Codable, Hashable, Sendable {
    let appCount: MarketCountInfo
    let crateVersion: String
    let developerCount: Int
    let pageSizeMax: Int
    let substanceCount: Int
    let syncStatus: SyncStatusInfo
}

nonisolated struct FlexibleDouble: Codable, Hashable, Sendable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            value = number
        } else if let text = try? container.decode(String.self), let number = Double(text) {
            value = number
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a number or numeric string")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

nonisolated struct FlexibleText: Codable, Hashable, Sendable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            value = text
        } else if let integer = try? container.decode(Int64.self) {
            value = String(integer)
        } else if let number = try? container.decode(Double.self) {
            value = String(number)
        } else if let boolean = try? container.decode(Bool.self) {
            value = String(boolean)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a scalar value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

nonisolated struct ScreenshotInfo: Codable, Hashable, Sendable, Identifiable {
    let url: String
    let resolution: String
    let rotated: Int

    var id: String { url }
    var remoteURL: URL? {
        guard let candidate = URL(string: url), candidate.scheme?.lowercased() == "https" else {
            return nil
        }
        return candidate
    }
}

nonisolated struct MarketApp: Codable, Hashable, Sendable, Identifiable {
    let appId: String
    let iconUrl: String?
    let createdAt: String
    let description: String
    let devEnName: String
    let developerName: String
    let downloadCount: Int64
    let kindName: String
    let kindTypeName: String
    let listedAt: String
    let mainDeviceCodes: [String]
    let metricsCreatedAt: String
    let minsdk: Int
    let name: String
    let pkgName: String
    let releaseDate: Int64
    let sizeBytes: Int64
    let updatedAt: String
    let version: String
    let versionCode: Int64
    let supplier: String
    let tagName: String
    let targetSdk: Int
    let compileSdkVersion: Int
    let releaseCountries: [String]?
    let recordalEntityTitle: String?
    let recordalEntityName: String?
    let appRecordalInfo: String?
    let averageRating: FlexibleDouble?
    let fullAverageRating: FlexibleDouble?
    let onlyStarCount: Int?
    let star1RatingCount: Int?
    let star2RatingCount: Int?
    let star3RatingCount: Int?
    let star4RatingCount: Int?
    let star5RatingCount: Int?
    let totalStarRatingCount: Int?
    let ratingCreatedAt: String?
    let allianceAppId: String?
    let briefDesc: String?
    let privacyUrl: String?
    let screenShots: [String]?
    let newScreenShots: [ScreenshotInfo]?
    let newFeatures: String?
    let upgradeMsg: String?
    let price: FlexibleText?
    let iap: Bool?
    let hms: Bool?
    let isPay: Bool?
    let minHmosApiLevel: Int?
    let apiReleaseType: String?
    let infoScore: FlexibleDouble?
    let infoRateCount: Int?

    var id: String { appId }
    var iconURL: URL? {
        guard let raw = iconUrl,
              let candidate = URL(string: raw),
              candidate.scheme?.lowercased() == "https" else { return nil }
        return candidate
    }
    var screenshots: [ScreenshotInfo] {
        if let newScreenShots, !newScreenShots.isEmpty { return newScreenShots }
        return (screenShots ?? []).map { ScreenshotInfo(url: $0, resolution: "", rotated: 0) }
    }
    var displayRating: Double? { fullAverageRating?.value ?? averageRating?.value }
}

nonisolated struct AppDetailPayload: Codable, Hashable, Sendable {
    let fullInfo: MarketApp
    let getData: Bool
    let newApp: Bool
    let newInfo: Bool
    let newMetric: Bool
    let newRating: Bool
    let cached: Bool?
}

nonisolated struct PageInfo<Value: Codable & Sendable>: Codable, Sendable {
    let data: [Value]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

nonisolated struct AppsPageQuery: Hashable, Sendable {
    var page = 1
    var pageSize = 20
    var sort = "download_count"
    var descending = true
    var searchKey: String?
    var searchValue: String?
    var exact = false
    var excludeHuawei = false
    var excludeAtomic = false
}

nonisolated enum SearchOperator: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case equal = "eq"
    case notEqual = "ne"
    case like
    case notLike = "not_like"
    case caseInsensitiveLike = "i_like"
    case notCaseInsensitiveLike = "not_i_like"
    case greaterThan = "gt"
    case greaterThanOrEqual = "gte"
    case lessThan = "lt"
    case lessThanOrEqual = "lte"
    case isNull = "is_null"
    case isNotNull = "is_not_null"
    case arrayContains = "array_contains"
    case arrayOverlaps = "array_overlaps"
    case arrayContainedBy = "array_contained_by"

    var id: String { rawValue }
    var needsValue: Bool { self != .isNull && self != .isNotNull }
    var title: String {
        switch self {
        case .equal: "等于"
        case .notEqual: "不等于"
        case .like: "包含（区分大小写）"
        case .notLike: "不包含（区分大小写）"
        case .caseInsensitiveLike: "包含（忽略大小写）"
        case .notCaseInsensitiveLike: "不包含（忽略大小写）"
        case .greaterThan: "大于"
        case .greaterThanOrEqual: "大于或等于"
        case .lessThan: "小于"
        case .lessThanOrEqual: "小于或等于"
        case .isNull: "为空"
        case .isNotNull: "不为空"
        case .arrayContains: "数组包含全部"
        case .arrayOverlaps: "数组存在交集"
        case .arrayContainedBy: "数组被包含"
        }
    }
}

nonisolated struct SearchCondition: Codable, Hashable, Sendable, Identifiable {
    var id = UUID()
    var key: String
    var op: SearchOperator
    var value: String?

    enum CodingKeys: String, CodingKey { case key, op, value }

    init(key: String = "name", op: SearchOperator = .caseInsensitiveLike, value: String? = "") {
        self.key = key
        self.op = op
        self.value = value
    }
}

nonisolated struct SearchExpression: Codable, Hashable, Sendable {
    let and: [SearchCondition]?
    let or: [SearchCondition]?

    static func build(useAnd: Bool, conditions: [SearchCondition]) -> SearchExpression? {
        let valid = conditions.compactMap { condition -> SearchCondition? in
            let key = condition.key.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = condition.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !condition.op.needsValue || !(value ?? "").isEmpty else { return nil }
            return SearchCondition(key: key, op: condition.op, value: condition.op.needsValue ? value : nil)
        }
        guard !valid.isEmpty else { return nil }
        return SearchExpression(and: useAnd ? valid : nil, or: useAnd ? nil : valid)
    }
}

nonisolated struct DailyMaxDownloadApp: Codable, Hashable, Sendable, Identifiable {
    let appId: String
    let appName: String
    let pkgName: String
    let downloadCount: Int64
    let reportDate: String

    var id: String { "\(appId)-\(reportDate)" }
}

nonisolated struct DownloadGrowthApp: Codable, Hashable, Sendable, Identifiable {
    let appId: String
    let name: String
    let pkgName: String
    let currentPeriodDate: String
    let priorPeriodDate: String
    let currentDownloadCount: Int64
    let priorDownloadCount: Int64
    let downloadIncrement: Int64

    var id: String { "\(appId)-\(currentPeriodDate)" }
}

nonisolated struct DeveloperRankingEntry: Codable, Hashable, Sendable, Identifiable {
    let developerId: String
    let developerName: String
    let appCount: Int

    var id: String { developerId }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        developerId = try container.decode(String.self)
        developerName = try container.decode(String.self)
        appCount = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(developerId)
        try container.encode(developerName)
        try container.encode(appCount)
    }
}

nonisolated struct RatingDistribution: Codable, Hashable, Sendable {
    let star1: Int
    let star2: Int
    let star3: Int
    let star4: Int
    let star5: Int

    var values: [(star: Int, count: Int)] {
        [(1, star1), (2, star2), (3, star3), (4, star4), (5, star5)]
    }
}

nonisolated struct SDKDistributionPoint: Codable, Hashable, Sendable, Identifiable {
    let sdk: Int
    let count: Int

    var id: Int { sdk }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sdk = try container.decode(Int.self)
        count = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sdk)
        try container.encode(count)
    }
}

nonisolated struct APIHistorySnapshot: Codable, Hashable, Sendable, Identifiable {
    let date: String
    let percentages: [String: Double]

    var id: String { date }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        date = try container.decode(String.self)
        percentages = try container.decode([String: Double].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(date)
        try container.encode(percentages)
    }
}

nonisolated struct AppMetric: Codable, Hashable, Sendable, Identifiable {
    let version: String
    let versionCode: Int64
    let sizeBytes: Int64
    let downloadCount: Int64
    let releaseDate: Int64
    let targetSdk: Int
    let minsdk: Int
    let compileSdkVersion: Int
    let minHmosApiLevel: Int
    let apiReleaseType: String
    let createdAt: String
    let infoScore: FlexibleDouble?
    let infoRateCount: Int?

    var id: String { "\(versionCode)-\(createdAt)" }
}

nonisolated struct AppRatingHistory: Codable, Hashable, Sendable, Identifiable {
    let reportDate: String
    let appId: String
    let pkgName: String
    let dailyNewCount: Int
    let dailyNewAverage: FlexibleDouble
    let cumulativeTotalCount: Int
    let cumulativeAvgRatingOrigin: FlexibleDouble?
    let cumulativeAvgRatingHighPrec: FlexibleDouble

    var id: String { "\(appId)-\(reportDate)" }
}

nonisolated struct DashboardVisibilityConfig: Codable, Hashable, Sendable {
    let showInstallCount: Bool
    let showTotalDownloadRanking: Bool
    let showDownloadHistory: Bool
    let showNonHuaweiDownloadRanking: Bool
    let showAppDownloadMetrics: Bool
    let showTSite: Bool

    static let restricted = DashboardVisibilityConfig(
        showInstallCount: false,
        showTotalDownloadRanking: false,
        showDownloadHistory: false,
        showNonHuaweiDownloadRanking: false,
        showAppDownloadMetrics: false,
        showTSite: false
    )
}

nonisolated struct DashboardVisibilityPayload: Codable, Hashable, Sendable {
    let showInstallCount: Bool?
    let showTotalDownloadRanking: Bool?
    let showDownloadHistory: Bool?
    let showNonHuaweiDownloadRanking: Bool?
    let showAppDownloadMetrics: Bool?
    let showTSite: Bool?
}

nonisolated struct AppDetailTarget: Hashable, Sendable {
    let appId: String?
    let packageName: String?
    let preview: MarketApp?

    init(appId: String? = nil, packageName: String? = nil, preview: MarketApp? = nil) {
        self.appId = appId
        self.packageName = packageName
        self.preview = preview
    }
}
