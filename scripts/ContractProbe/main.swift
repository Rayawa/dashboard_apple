import Foundation

private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()

private func decode<Value: Decodable>(_ type: Value.Type, path: String) throws -> Value {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try decoder.decode(Value.self, from: data)
}

do {
    let market = try decode(APIEnvelope<MarketInfo>.self, path: "/tmp/dashboard-market-info.json")
    let apps = try decode(APIEnvelope<PageInfo<MarketApp>>.self, path: "/tmp/dashboard-app-list.json")
    let advanced = try decode(APIEnvelope<PageInfo<MarketApp>>.self, path: "/tmp/dashboard-advanced-query.json")
    let rating = try decode(APIEnvelope<RatingDistribution>.self, path: "/tmp/dashboard-rating.json")
    let sdk = try decode(APIEnvelope<[SDKDistributionPoint]>.self, path: "/tmp/dashboard-sdk.json")
    let apiHistory = try decode(APIEnvelope<[APIHistorySnapshot]>.self, path: "/tmp/dashboard-api-history.json")
    let developers = try decode(APIEnvelope<[DeveloperRankingEntry]>.self, path: "/tmp/dashboard-developers.json")
    let daily = try decode(APIEnvelope<[DailyMaxDownloadApp]>.self, path: "/tmp/dashboard-daily.json")
    let growth = try decode(APIEnvelope<[DownloadGrowthApp]>.self, path: "/tmp/dashboard-growth.json")
    let metrics = try decode(APIEnvelope<[AppMetric]>.self, path: "/tmp/dashboard-metrics.json")
    let history = try decode(APIEnvelope<[AppRatingHistory]>.self, path: "/tmp/dashboard-rating-history.json")
    let config = try decode(APIEnvelope<DashboardVisibilityPayload>.self, path: "/tmp/dashboard-config.json")

    precondition(market.success && apps.success && advanced.success && rating.success && sdk.success)
    precondition(apiHistory.success && developers.success && daily.success && growth.success)
    precondition(metrics.success && history.success && config.success)

    print("market=\(market.data.appCount.total)")
    print("apps=\(apps.data.data.count)/\(apps.data.totalCount)")
    print("advanced=\(advanced.data.data.count)/\(advanced.data.totalCount)")
    print("rating=\(rating.data.values.count)")
    print("sdk=\(sdk.data.count)")
    print("apiHistory=\(apiHistory.data.count)")
    print("developers=\(developers.data.count)")
    print("daily=\(daily.data.count)")
    print("growth=\(growth.data.count)")
    print("metrics=\(metrics.data.count)")
    print("ratingHistory=\(history.data.count)")
    print("visibility=\([config.data.showInstallCount, config.data.showTotalDownloadRanking, config.data.showDownloadHistory, config.data.showNonHuaweiDownloadRanking, config.data.showAppDownloadMetrics, config.data.showTSite].compactMap { $0 }.filter { $0 }.count)/6 enabled")

    let deepLinks = [
        URL(string: "hmdashboard://app?app_id=C10084839")!,
        URL(string: "https://appgallery.huawei.com/app/detail?id=com.example.demo")!,
        URL(string: "https://shenjack.top:10003/dashboard?app_id=C123456")!,
    ].compactMap(DashboardDeepLink.appTarget)
    precondition(deepLinks.count == 3)
    precondition(deepLinks[0].appId == "C10084839")
    precondition(deepLinks[1].packageName == "com.example.demo")
    precondition(deepLinks[2].appId == "C123456")
    print("deepLinks=\(deepLinks.count)")

    let pastedInputs = [
        "请帮我查询 c10084839",
        "包名：cn.biandangroup.getrace，谢谢",
        "123456",
    ].compactMap(DashboardInputParser.target)
    precondition(pastedInputs.count == 3)
    precondition(pastedInputs[0].appId == "C10084839")
    precondition(pastedInputs[1].packageName == "cn.biandangroup.getrace")
    precondition(pastedInputs[2].appId == "C123456")
    print("pastedInputs=\(pastedInputs.count)")
} catch {
    fputs("contract probe failed: \(error)\n", stderr)
    exit(1)
}
