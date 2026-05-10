import Foundation

private struct SubmitAppBody: Encodable {
    struct CommentInfo: Encodable {
        let platform: String
        let user: String?
        let note: String?
    }

    let app_id: String?
    let pkg_name: String?
    let comment: CommentInfo?
}

private struct BaseAPIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let timestamp: String?
}

private struct SearchAppItem: Decodable {
    let app_id: String
    let name: String
}

private struct SearchAppList: Decodable {
    let data: [SearchAppItem]
}

private struct SearchResponse: Decodable {
    let success: Bool
    let data: SearchAppList
}

private struct AppDetailPayload: Decodable {
    struct FullInfo: Decodable {
        let alliance_app_id: String?
    }

    let full_info: FullInfo?
}

enum APIError: LocalizedError {
    case invalidInput(String)
    case invalidResponse
    case server(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message), .server(let message), .notFound(let message):
            message
        case .invalidResponse:
            "服务返回了无法解析的数据"
        }
    }
}

enum AppAPIService {
    private static let apiBase = DashboardURLs.sAPIBase

    static func submitPlatform() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersionString
        #if os(macOS)
        return "ray_dashboard/\(DashboardMeta.appVersion)-macOS \(version)"
        #else
        return "ray_dashboard/\(DashboardMeta.appVersion)-iOS \(version)"
        #endif
    }

    static func submitApp(packageName: String, appId: String, userName: String, remark: String) async throws {
        let trimmedPackage = packageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPackage.isEmpty else {
            throw APIError.invalidInput("请输入包名")
        }

        let trimmedAppId = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUser = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemark = remark.trimmingCharacters(in: .whitespacesAndNewlines)

        let payload = SubmitAppBody(
            app_id: trimmedPackage.isEmpty ? trimmedAppId : nil,
            pkg_name: trimmedPackage,
            comment: SubmitAppBody.CommentInfo(
                platform: submitPlatform(),
                user: trimmedUser.isEmpty ? nil : trimmedUser,
                note: trimmedRemark.isEmpty ? nil : trimmedRemark
            )
        )

        var request = URLRequest(url: apiBase.appending(path: "submit"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UAProvider.customUserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server("提交失败，服务返回 \(httpResponse.statusCode)")
        }
    }

    static func appId(byPackage packageName: String) async throws -> String {
        let encoded = packageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? packageName
        let response: BaseAPIResponse<AppDetailPayload> = try await fetch("apps/pkg_name/\(encoded)")
        guard response.success, let appID = response.data?.full_info?.alliance_app_id else {
            throw APIError.notFound("包名转换失败")
        }
        return normalize(appID)
    }

    static func appId(byName appName: String) async throws -> String {
        var components = URLComponents(url: apiBase.appending(path: "apps/list/0"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page_size", value: "5"),
            URLQueryItem(name: "detail", value: "false"),
            URLQueryItem(name: "search_key", value: "name"),
            URLQueryItem(name: "search_value", value: appName),
            URLQueryItem(name: "search_exact", value: "false"),
        ]
        guard let url = components?.url else {
            throw APIError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.server("应用名称查询失败")
        }
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        guard decoded.success, let first = decoded.data.data.first else {
            throw APIError.notFound("未找到匹配的应用名称")
        }
        return normalize(first.app_id)
    }

    static func verify(appId: String) async throws -> Bool {
        let response: BaseAPIResponse<AppDetailPayload> = try await fetch("apps/app_id/\(appId)")
        return response.success
    }

    static func resultURL(for appId: String) -> URL {
        DashboardURLs.tBase.appending(path: "app/\(appId)")
    }

    private static func normalize(_ appId: String) -> String {
        appId.hasPrefix("C") ? appId : "C\(appId)"
    }

    private static func fetch<T: Decodable>(_ path: String) async throws -> T {
        let url = apiBase.appending(path: path)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.server("网络请求失败")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
