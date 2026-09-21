import Foundation

/// Converts pasted IDs, package names, links, and short pieces of shared text into a native detail target.
nonisolated enum DashboardInputParser {
    private static let appIDPattern = "^[Cc]?[0-9]{5,32}$"
    private static let packagePattern = "^[A-Za-z0-9_]+(?:[.-][A-Za-z0-9_]+)+$"

    static func target(from text: String) -> AppDetailTarget? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if isAppID(value) { return .init(appId: normalizedAppID(value)) }
        if isPackageName(value) { return .init(packageName: value) }
        if let components = URLComponents(string: value), let target = target(from: components) {
            return target
        }
        if let id = firstCapturedMatch(
            in: value,
            pattern: #"(?<![A-Za-z0-9_])([Cc][0-9]{5,32})(?![A-Za-z0-9_])"#
        ) {
            return .init(appId: normalizedAppID(id))
        }
        if let package = firstCapturedMatch(
            in: value,
            pattern: #"(?<![A-Za-z0-9_.-])((?:com|cn|org|net|io|top|me|dev|app|ohos)\.[A-Za-z0-9_]+(?:[.-][A-Za-z0-9_]+)*)(?![A-Za-z0-9_.-])"#,
            options: [.caseInsensitive]
        ) {
            return .init(packageName: package)
        }
        return nil
    }

    static func target(from url: URL) -> AppDetailTarget? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        return target(from: components)
    }

    private static func target(from components: URLComponents) -> AppDetailTarget? {
        let items = components.queryItems ?? []
        if let id = value(in: items, keys: ["app_id", "appid"]), isAppID(id) {
            return .init(appId: normalizedAppID(id))
        }
        if let id = value(in: items, keys: ["id"]) {
            if isAppID(id) { return .init(appId: normalizedAppID(id)) }
            if isPackageName(id) { return .init(packageName: id) }
        }
        if let package = value(in: items, keys: ["pkg", "pkg_name", "package", "package_name"]),
           isPackageName(package) {
            return .init(packageName: package)
        }

        let values = components.path.split(separator: "/").map(String.init)
        if let id = values.last(where: isAppID) { return .init(appId: normalizedAppID(id)) }
        if let package = values.last(where: isPackageName) { return .init(packageName: package) }
        return nil
    }

    private static func value(in items: [URLQueryItem], keys: Set<String>) -> String? {
        items.first { keys.contains($0.name.lowercased()) }?.value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedAppID(_ value: String) -> String {
        value.first == "C" || value.first == "c"
            ? "C\(value.dropFirst())"
            : "C\(value)"
    }

    private static func isAppID(_ value: String) -> Bool {
        value.range(of: appIDPattern, options: .regularExpression) != nil
    }

    private static func isPackageName(_ value: String) -> Bool {
        value.range(of: packagePattern, options: .regularExpression) != nil
    }

    private static func firstCapturedMatch(
        in value: String,
        pattern: String,
        options: NSRegularExpression.Options = []
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options),
              let match = regex.firstMatch(
                  in: value,
                  range: NSRange(value.startIndex..<value.endIndex, in: value)
              ),
              let range = Range(match.range(at: 1), in: value) else { return nil }
        return String(value[range])
    }
}
